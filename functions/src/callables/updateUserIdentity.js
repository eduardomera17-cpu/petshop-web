// functions/src/callables/updateUserIdentity.js
// Callable de modificación de identidad de cuentas de usuario por el Super Usuario
// (TRD §3.4.I, PRD CF-08, CA-AD-12, CA-AD-19, CA-AD-35, CF-11)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import {
  isValidFullName,
  isValidPhone,
  isValidDocumentType,
  isValidDocumentNumber,
  isValidAddress,
  normalizeSearchName,
} from '../domain/validators.js';
import { recordAuditLog } from '../lib/audit.js';

export const updateUserIdentity = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Control de autenticación y rol (exclusivo para SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, ROLES.SUPERADMIN);

    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta del llamante no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    const callerUid = request.auth.uid;
    const data = request.data || {};
    const { targetUid } = data;

    if (!targetUid || typeof targetUid !== 'string' || targetUid.trim() === '') {
      throw new HttpsError('invalid-argument', 'targetUid es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedTargetUid = targetUid.trim();

    // 2. INVARIANTE INVIOLABLE CA-AD-12: Prohibido cambiar el rol de una cuenta existente
    if ('role' in data) {
      throw new HttpsError('failed-precondition', 'El rol de una cuenta existente no puede modificarse.', {
        errorCode: 'ROLE_CHANGE_NOT_SUPPORTED',
      });
    }

    // 3. INVARIANTE: Prohibido modificar el correo electrónico
    if ('email' in data) {
      throw new HttpsError('invalid-argument', 'El correo electrónico no puede ser modificado.', {
        errorCode: 'EMAIL_NOT_MODIFIABLE',
      });
    }

    // 4. Verificación de existencia del usuario objetivo
    const userRef = db.collection('users').doc(trimmedTargetUid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'Usuario no encontrado.', {
        errorCode: 'NOT_FOUND',
      });
    }

    const userData = userDoc.data() || {};

    // 5. INVARIANTE INVIOLABLE CA-AD-19, CF-11: El Super Usuario es inmutable
    if (userData.role === ROLES.SUPERADMIN) {
      throw new HttpsError('permission-denied', 'El Super Usuario es inmutable.', {
        errorCode: 'SUPERADMIN_IMMUTABLE',
      });
    }

    // 6. Validación de campos editables de identidad
    const updates = {};

    if (data.fullName !== undefined) {
      if (!isValidFullName(data.fullName)) {
        throw new HttpsError('invalid-argument', 'Nombre completo inválido (1-100 caracteres).', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      const trimmedName = data.fullName.trim();
      updates.fullName = trimmedName;
      updates.searchName = normalizeSearchName(trimmedName);
    }

    if (data.phone !== undefined) {
      if (!isValidPhone(data.phone)) {
        throw new HttpsError('invalid-argument', 'Teléfono inválido (formato ecuatoriano +593 seguido de 9 dígitos).', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      updates.phone = data.phone.trim();
    }

    if (data.documentType !== undefined || data.documentNumber !== undefined) {
      const docType = data.documentType !== undefined ? data.documentType : userData.documentType;
      const docNum = data.documentNumber !== undefined ? data.documentNumber : userData.documentNumber;

      if (!isValidDocumentType(docType) || !isValidDocumentNumber(docType, docNum)) {
        throw new HttpsError('invalid-argument', 'Tipo o número de documento de identidad inválido.', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }

      if (data.documentType !== undefined) updates.documentType = data.documentType.trim();
      if (data.documentNumber !== undefined) updates.documentNumber = data.documentNumber.trim();
    }

    if (data.address !== undefined) {
      if (!isValidAddress(data.address)) {
        throw new HttpsError('invalid-argument', 'Dirección inválida (1-200 caracteres).', {
          errorCode: 'INVALID_ARGUMENT',
        });
      }
      updates.address = data.address.trim();
    }

    if (Object.keys(updates).length === 0) {
      throw new HttpsError('invalid-argument', 'Se debe proporcionar al menos un campo válido para actualizar.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    // 7. Aplicación de mutación en Firestore (sin tocar bloques congelados en citas ni historias clínicas, CA-AD-35)
    const now = FieldValue.serverTimestamp();
    updates['audit.updatedBy'] = callerUid;
    updates['audit.updatedAt'] = now;

    await userRef.update(updates);

    // Sincronizar displayName en Auth si cambió fullName
    if (updates.fullName) {
      try {
        await auth.updateUser(trimmedTargetUid, { displayName: updates.fullName });
      } catch (authErr) {
        console.warn(`[updateUserIdentity] No se pudo actualizar displayName en Auth para ${trimmedTargetUid}:`, authErr.message);
      }
    }

    // 8. Trazabilidad inmutable en /audit_log (TRD §2.12, N-AD-08)
    await recordAuditLog(db, {
      actorUid: callerUid,
      actorName: request.auth.token?.name || 'Super Usuario',
      actorRole: ROLES.SUPERADMIN,
      action: 'UPDATE_USER_IDENTITY',
      targetType: 'USER',
      targetId: trimmedTargetUid,
      metadata: {
        updatedFields: Object.keys(updates).filter((k) => !k.startsWith('audit.')),
      },
    });

    return {
      success: true,
      targetUid: trimmedTargetUid,
      updatedFields: Object.keys(updates).filter((k) => !k.startsWith('audit.')),
    };
  }
);
