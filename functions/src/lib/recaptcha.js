// functions/src/lib/recaptcha.js
// Implementación oficial de createAssessment según TRD §4.3.3.A y ADR-014

import { RecaptchaEnterpriseServiceClient } from '@google-cloud/recaptcha-enterprise';
import { HttpsError } from 'firebase-functions/v2/https';
import { RECAPTCHA_SCORE_SITE_KEY } from '../config/constants.js';

let recaptchaClientInstance = null;

/**
 * Identificador del proyecto de Google Cloud. Firebase garantiza FIREBASE_CONFIG (con projectId) en el
 * entorno de ejecución y en el emulador; GCLOUD_PROJECT lo suelen definir ambos, pero no está garantizado.
 */
function resolveProjectId() {
  if (process.env.GCLOUD_PROJECT) return process.env.GCLOUD_PROJECT;
  try {
    return JSON.parse(process.env.FIREBASE_CONFIG ?? '{}').projectId;
  } catch {
    return undefined;
  }
}

function getClient() {
  if (!recaptchaClientInstance) {
    recaptchaClientInstance = new RecaptchaEnterpriseServiceClient();
  }
  return recaptchaClientInstance;
}

/**
 * Crea una evaluación de riesgo para analizar una acción ejecutada en el cliente.
 *
 * @param {Object} params
 * @param {string} params.token - Token generado por grecaptcha.enterprise.execute()
 * @param {string} [params.recaptchaAction] - Nombre esperado de la acción (opcional para claves de casilla, ADR-014)
 * @param {number} [params.minScore=0.5] - Umbral mínimo de confianza (0.0 a 1.0)
 * @param {string} [params.projectID] - Project ID de Google Cloud (por defecto GCLOUD_PROJECT o el de FIREBASE_CONFIG)
 * @param {string} [params.recaptchaKey=RECAPTCHA_SCORE_SITE_KEY] - Clave de sitio (variable de entorno RECAPTCHA_SCORE_SITE_KEY)
 * @returns {Promise<number>} Puntuación de riesgo validada
 */
export async function createAssessment({
  token,
  recaptchaAction,
  minScore = 0.5,
  projectID = resolveProjectId(),
  recaptchaKey = RECAPTCHA_SCORE_SITE_KEY,
}) {
  if (!token) {
    throw new HttpsError('invalid-argument', 'El token de reCAPTCHA es obligatorio.', {
      errorCode: 'VERIFICATION_REQUIRED',
    });
  }

  if (!projectID) {
    console.error('No se pudo determinar el project ID de Google Cloud (GCLOUD_PROJECT / FIREBASE_CONFIG).');
    throw new HttpsError('unavailable', 'Servicio de verificación no disponible temporalmente.', {
      errorCode: 'VERIFICATION_UNAVAILABLE',
    });
  }

  const client = getClient();
  const projectPath = typeof client.projectPath === 'function'
    ? client.projectPath(projectID)
    : `projects/${projectID}`;

  const request = {
    assessment: {
      event: {
        token: token,
        siteKey: recaptchaKey,
      },
    },
    parent: projectPath,
  };

  let response;
  try {
    const [res] = await client.createAssessment(request);
    response = res;
  } catch (error) {
    console.error('Error al invocar Google Cloud reCAPTCHA Enterprise API:', error);
    throw new HttpsError('unavailable', 'Servicio de verificación no disponible temporalmente.', {
      errorCode: 'VERIFICATION_UNAVAILABLE',
    });
  }

  // 1. Verificación de validez y caducidad del token (TTL 2 minutos)
  if (!response.tokenProperties || !response.tokenProperties.valid) {
    const reason = response.tokenProperties?.invalidReason || 'UNKNOWN_REASON';
    console.warn(`Evaluación rechazada: Token inválido por motivo: ${reason}`);
    throw new HttpsError('permission-denied', `Verificación rechazada: ${reason}`, {
      errorCode: 'VERIFICATION_FAILED',
      reason: reason,
    });
  }

  // 2. Verificación estricta de la acción esperada (Evita reutilización cruzada de tokens).
  //    Se omite cuando no se pasa recaptchaAction: los tokens de la clave de
  //    casilla (VerificacionPersona) no transportan acción — ADR-014.
  if (recaptchaAction && response.tokenProperties.action !== recaptchaAction) {
    console.warn(`Discrepancia de acción: esperada '${recaptchaAction}', recibida '${response.tokenProperties.action}'`);
    throw new HttpsError('permission-denied', 'La acción de seguridad no coincide con la operación solicitada.', {
      errorCode: 'VERIFICATION_ACTION_MISMATCH',
    });
  }

  // 3. Verificación de umbral de puntuación de riesgo (Score >= 0.5)
  const score = response.riskAnalysis?.score ?? 0.0;
  console.info(`Evaluación de riesgo aprobada para acción '${recaptchaAction || 'NONE'}' con score: ${score}`);

  if (score < minScore) {
    console.warn(`Puntuación de riesgo insuficiente (${score} < ${minScore}). Motivos:`, response.riskAnalysis?.reasons);
    throw new HttpsError('permission-denied', 'Puntuación de riesgo insuficiente para ejecutar esta operación.', {
      errorCode: 'VERIFICATION_HIGH_RISK',
      score: score,
      reasons: response.riskAnalysis?.reasons,
    });
  }

  return score;
}
