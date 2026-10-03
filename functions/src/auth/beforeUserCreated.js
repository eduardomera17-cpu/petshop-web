// functions/src/auth/beforeUserCreated.js
// Blocking function que garantiza verificación humana inesquivable antes del alta (TRD §3.1.A, A-01, A-09, CA-24, ADR-022)

import { beforeUserCreated as beforeUserCreatedTrigger, HttpsError } from 'firebase-functions/v2/identity';
import { FieldValue } from 'firebase-admin/firestore';
import crypto from 'node:crypto';
import { db } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS } from '../config/constants.js';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const beforeUserCreated = beforeUserCreatedTrigger(
  {
    region: REGIONS.FIRESTORE,
  },
  async (event) => {
    const user = event.data;
    const email = user?.email;
    const uid = user?.uid;

    // 1. Validación de formato de correo
    if (!email || typeof email !== 'string' || !EMAIL_REGEX.test(email.trim())) {
      throw new HttpsError('invalid-argument', 'El correo electrónico es obligatorio y debe tener formato válido.', {
        errorCode: 'INVALID_EMAIL',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const checkKey = crypto.createHash('sha256').update(normalizedEmail).digest('hex');

    // 2. Exigir la prueba de humanidad en /human_checks/{sha256(email)}
    const checkDoc = await db.collection('human_checks').doc(checkKey).get();

    if (!checkDoc.exists) {
      console.warn(`Alta abortada: Intento de registro sin verifyHuman (huella ${checkKey.slice(0, 8)})`);
      throw new HttpsError('permission-denied', 'Se requiere verificación humana para registrar una cuenta.', {
        errorCode: 'VERIFICATION_REQUIRED',
      });
    }

    const checkData = checkDoc.data();
    const expiresAt = checkData?.expiresAt?.toMillis
      ? checkData.expiresAt.toMillis()
      : (typeof checkData?.expiresAt === 'number' ? checkData.expiresAt : 0);

    if (Date.now() > expiresAt) {
      console.warn(`Alta abortada: Prueba de verifyHuman caducada (huella ${checkKey.slice(0, 8)})`);
      throw new HttpsError('permission-denied', 'La verificación de seguridad ha caducado. Vuelva a intentarlo.', {
        errorCode: 'VERIFICATION_REQUIRED',
      });
    }

    // REGLA CRÍTICA: La prueba se valida, NO se consume aquí.
    // beforeUserSignedIn del mismo flujo inmediato la necesita viva. Caduca sola por TTL.

    // 3. Escribir documento mínimo en /users/{uid} en la base petshopdev
    await db.collection('users').doc(uid).set({
      uid: uid,
      email: normalizedEmail,
      role: ROLES.CLIENT,
      status: USER_STATUS.PENDING_PROFILE,
      audit: {
        createdAt: FieldValue.serverTimestamp(),
      },
    });

    // 4. Asignación automática de claims autoritativos
    return {
      customClaims: {
        role: ROLES.CLIENT,
        status: USER_STATUS.PENDING_PROFILE,
      },
    };
  }
);
