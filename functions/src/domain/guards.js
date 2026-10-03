// functions/src/domain/guards.js
// Interceptores y validaciones de seguridad para Callables y mutaciones (TRD §4.2, §4.3.3.B)

import { HttpsError } from 'firebase-functions/v2/https';
import { createAssessment } from '../lib/recaptcha.js';
import { auth, db } from '../config/firebase.js';

/**
 * Valida obligatoriamente la presencia y calidad de la evaluación de reCAPTCHA
 * antes de ejecutar cualquier transacción crítica de negocio.
 *
 * @param {Object} requestData - Datos de la petición conteniendo recaptchaToken
 * @param {string} expectedAction - Nombre de la acción esperada ('BOOK_APPOINTMENT', 'DELIVER_PROFORMA', etc.)
 * @param {number} [minScore=0.5] - Umbral mínimo requerido
 */
export async function assertRecaptchaAssessment(requestData, expectedAction, minScore = 0.5) {
  const token = requestData?.recaptchaToken;
  if (!token) {
    throw new HttpsError('permission-denied', 'Se requiere verificación de seguridad para continuar.', {
      errorCode: 'VERIFICATION_REQUIRED',
    });
  }

  await createAssessment({
    token: token,
    recaptchaAction: expectedAction,
    minScore: minScore,
  });
}

/**
 * Valida la atestación de Firebase App Check en peticiones entrantes.
 *
 * @param {Object} request - Request context de la Cloud Function v2
 */
export function assertAppCheck(request) {
  if (!request || !request.app) {
    throw new HttpsError('unauthenticated', 'La petición no superó la verificación de App Check.', {
      errorCode: 'APP_CHECK_REQUIRED',
    });
  }
}

/**
 * Valida que el llamante posea uno de los roles permitidos en sus claims autoritativos.
 *
 * @param {Object} authContext - Contexto de autenticación (request.auth)
 * @param {string|string[]} allowedRoles - Rol único o lista de roles permitidos
 */
export function assertRole(authContext, allowedRoles) {
  if (!authContext || !authContext.token) {
    throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
      errorCode: 'UNAUTHENTICATED',
    });
  }

  const role = authContext.token.role;
  const rolesArray = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  if (!role || !rolesArray.includes(role)) {
    throw new HttpsError('permission-denied', 'Permisos insuficientes para realizar esta acción.', {
      errorCode: 'INSUFFICIENT_ROLE',
    });
  }
}

/**
 * Valida que el llamante sea el propietario del recurso o un administrador.
 *
 * @param {Object} authContext - Contexto de autenticación (request.auth)
 * @param {string} resourceOwnerUid - UID del propietario del recurso
 */
export function assertOwner(authContext, resourceOwnerUid) {
  if (!authContext || !authContext.uid) {
    throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
      errorCode: 'UNAUTHENTICATED',
    });
  }

  const isOwner = authContext.uid === resourceOwnerUid;
  const isAdmin = authContext.token?.role === 'ADMIN' || authContext.token?.role === 'SUPERADMIN';

  if (!isOwner && !isAdmin) {
    throw new HttpsError('permission-denied', 'No tiene permisos sobre este recurso.', {
      errorCode: 'PERMISSION_DENIED',
    });
  }
}

/**
 * Verifica el token de ID con revocación estricta y valida que la cuenta esté en estado ACTIVE.
 * Regla de implementación: Toda callable de mutación invoca mandatoriamente esta comprobación.
 *
 * @param {string} idToken - Token de ID JWT a verificar
 * @param {boolean} [checkRevoked=true] - Exigir comprobación de revocación de refresh tokens
 * @returns {Promise<Object>} Token decodificado
 */
export async function verifyIdToken(idToken, checkRevoked = true) {
  if (!idToken || typeof idToken !== 'string') {
    throw new HttpsError('unauthenticated', 'Token de autenticación obligatorio.', {
      errorCode: 'UNAUTHENTICATED',
    });
  }

  let decoded;
  try {
    decoded = await auth.verifyIdToken(idToken, checkRevoked);
  } catch (error) {
    console.warn('Error al verificar idToken (revocado o inválido):', error);
    throw new HttpsError('unauthenticated', 'Token de autenticación revocado o inválido.', {
      errorCode: 'UNAUTHENTICATED',
    });
  }

  const userDoc = await db.collection('users').doc(decoded.uid).get();
  if (!userDoc.exists || userDoc.data()?.status !== 'ACTIVE') {
    throw new HttpsError('permission-denied', 'La cuenta no está activa para realizar mutaciones.', {
      errorCode: 'ACCOUNT_NOT_ACTIVE',
    });
  }

  return decoded;
}
