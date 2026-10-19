// functions/src/callables/reactivateAccountOrPet.js
// Callable de reactivación de cuentas de usuario y mascotas con guarda de personal (TRD §3.4.I, CL-09, CF-12, CA-AD-38, CA-45, AUD-074, AUD-081, Caso Crítico 22)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const reactivateAccountOrPet = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y rol administrativo (ADMIN o SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, [ROLES.ADMIN, ROLES.SUPERADMIN]);

    const callerUid = request.auth.uid;
    const callerRole = request.auth.token?.role;

    // Verificar que la cuenta del llamante se encuentre activa
    if (request.auth.token?.status && request.auth.token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    // 2. Validación exhaustiva del esquema de entrada
    const { entityType, entityId } = request.data || {};

    if (!entityType || (entityType !== 'USER' && entityType !== 'PET')) {
      throw new HttpsError(
        'invalid-argument',
        'entityType es obligatorio y debe ser USER o PET.',
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    if (!entityId || typeof entityId !== 'string' || entityId.trim() === '') {
      throw new HttpsError(
        'invalid-argument',
        'entityId es obligatorio y debe ser una cadena válida.',
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    const trimmedEntityId = entityId.trim();
    const now = FieldValue.serverTimestamp();

    // 3. Rama A: Reactivación de cuenta de usuario (USER)
    if (entityType === 'USER') {
      const userRef = db.collection('users').doc(trimmedEntityId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'Usuario no encontrado.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const userData = userDoc.data() || {};
      const targetRole = userData.role;

      // Invariante de gobierno: Super Usuario es inmutable (CF-11 límite 1, CA-AD-19)
      if (targetRole === ROLES.SUPERADMIN) {
        throw new HttpsError('permission-denied', 'El Super Usuario es inmutable.', {
          errorCode: 'SUPERADMIN_IMMUTABLE',
        });
      }

      // GUARDA DE PERSONAL INVIOLABLE (TRD §3.4.I, AUD-074, AUD-081, Caso Crítico 22):
      // Si el usuario objetivo es personal (ADMIN), ÚNICAMENTE el SUPERADMIN puede reactivarlo.
      if (targetRole === ROLES.ADMIN && callerRole !== ROLES.SUPERADMIN) {
        throw new HttpsError(
          'permission-denied',
          'Staff reactivation requires superadmin privileges',
          { errorCode: 'STAFF_REACTIVATION_REQUIRES_SUPERADMIN' }
        );
      }

      // Validar que la cuenta esté efectivamente desactivada antes de reactivar (idempotencia y trazabilidad).
      if (userData.status !== USER_STATUS.DEACTIVATED) {
        throw new HttpsError('failed-precondition', 'La cuenta no se encuentra desactivada.', {
          errorCode: 'NOT_DEACTIVATED',
        });
      }

      // Transición en Firestore: DEACTIVATED -> ACTIVE
      await userRef.update({
        status: USER_STATUS.ACTIVE,
        deactivatedAt: null,
        deactivatedBy: null,
        'audit.updatedBy': callerUid,
        'audit.updatedAt': now,
      });

      // Sincronización autoritativa en Firebase Auth
      try {
        await auth.updateUser(trimmedEntityId, { disabled: false });
        const authUser = await auth.getUser(trimmedEntityId);
        const existingClaims = authUser.customClaims || {};
        await auth.setCustomUserClaims(trimmedEntityId, {
          ...existingClaims,
          status: USER_STATUS.ACTIVE,
        });
      } catch (authError) {
        console.warn(`[reactivateAccountOrPet] Sincronización Auth para ${trimmedEntityId}:`, authError.message);
      }

      // Trazabilidad inmutable en /audit_log (TRD §2.12, N-AD-08)
      await recordAuditLog(db, {
        actorUid: callerUid,
        actorName: request.auth.token?.name || 'Personal',
        actorRole: callerRole || ROLES.ADMIN,
        action: 'REACTIVATE_ACCOUNT',
        targetType: 'USER',
        targetId: trimmedEntityId,
        metadata: { targetRole },
      });

      // INVARIANTE DE NEGOCIO (CA-45): Las citas y solicitudes canceladas NO se restauran.
      return {
        success: true,
        entityType: 'USER',
        entityId: trimmedEntityId,
        status: USER_STATUS.ACTIVE,
      };
    }

    // 4. Rama B: Reactivación de mascota (PET)
    if (entityType === 'PET') {
      const petRef = db.collection('pets').doc(trimmedEntityId);
      const petDoc = await petRef.get();

      if (!petDoc.exists) {
        throw new HttpsError('not-found', 'Mascota no encontrada.', {
          errorCode: 'NOT_FOUND',
        });
      }

      // Validar que la mascota esté efectivamente desactivada antes de reactivar.
      const petData = petDoc.data() || {};
      if (petData.status !== 'DEACTIVATED') {
        throw new HttpsError('failed-precondition', 'La mascota no se encuentra desactivada.', {
          errorCode: 'NOT_DEACTIVATED',
        });
      }

      // Transición en Firestore: DEACTIVATED -> ACTIVE
      await petRef.update({
        status: 'ACTIVE',
        deactivatedAt: null,
        deactivatedBy: null,
        'audit.updatedBy': callerUid,
        'audit.updatedAt': now,
      });

      // Trazabilidad inmutable en /audit_log (TRD §2.12, N-AD-08)
      await recordAuditLog(db, {
        actorUid: callerUid,
        actorName: request.auth.token?.name || 'Personal',
        actorRole: callerRole || ROLES.ADMIN,
        action: 'REACTIVATE_PET',
        targetType: 'PET',
        targetId: trimmedEntityId,
        metadata: {},
      });

      // INVARIANTE DE NEGOCIO (CA-45): Las citas y solicitudes canceladas NO se restauran.
      return {
        success: true,
        entityType: 'PET',
        entityId: trimmedEntityId,
        status: 'ACTIVE',
      };
    }
  }
);
