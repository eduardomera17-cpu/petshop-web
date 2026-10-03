// functions/src/callables/verifyHuman.js
// Callable de verificación humana autoritativa para registro y acceso (TRD §3.1.C, A-10, ADR-014, ADR-022)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import crypto from 'node:crypto';
import { createAssessment } from '../lib/recaptcha.js';
import { db } from '../config/firebase.js';
import { REGIONS, RECAPTCHA_CHECKBOX_SITE_KEY, HUMAN_CHECK_TTL_MS, ENFORCE_APP_CHECK } from '../config/constants.js';

export const verifyHuman = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    const { token, email } = request.data ?? {};

    // Validación de parámetros obligatorios (la contraseña nunca entra aquí)
    if (!token || !email || typeof email !== 'string') {
      throw new HttpsError('invalid-argument', 'Token y correo son obligatorios.', {
        errorCode: 'VERIFICATION_REQUIRED',
      });
    }

    // Evaluación autoritativa contra la clave de CASILLA (ADR-014).
    // Sin recaptchaAction: un token de casilla no la transporta.
    await createAssessment({
      token,
      recaptchaKey: RECAPTCHA_CHECKBOX_SITE_KEY, // VerificacionPersona
      minScore: 0.5,
    });

    // Persistencia de prueba efímera con SHA-256 del correo en minúsculas
    const normalizedEmail = email.trim().toLowerCase();
    const checkKey = crypto.createHash('sha256').update(normalizedEmail).digest('hex');

    await db.collection('human_checks').doc(checkKey).set({
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + HUMAN_CHECK_TTL_MS), // TTL 2 min
    });

    return { verified: true };
  }
);
