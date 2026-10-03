// functions/src/callables/setAvailabilityBlock.js
// Callable de gestión de bloqueos administrativos de disponibilidad (TRD §3.2.I, AG-06, CA-AD-55, ADR-004)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const setAvailabilityBlock = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y rol exclusivo de personal (ADMIN o SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, [ROLES.ADMIN, ROLES.SUPERADMIN]);

    // Verificación de revocación si viene bearer token (TRD §4.2, §4.6)
    if (request.rawRequest?.headers?.authorization) {
      const authHeader = request.rawRequest.headers.authorization;
      if (typeof authHeader === 'string' && authHeader.startsWith('Bearer ')) {
        const idToken = authHeader.split('Bearer ')[1];
        try {
          await auth.verifyIdToken(idToken, true);
        } catch {
          throw new HttpsError('unauthenticated', 'Token de autenticación revocado o inválido.', {
            errorCode: 'UNAUTHENTICATED',
          });
        }
      }
    }

    const uid = request.auth.uid;
    const token = request.auth.token || {};

    if (token.status && token.status !== USER_STATUS.ACTIVE) {
      throw new HttpsError('permission-denied', 'Cuenta no activa.', {
        errorCode: 'ACCOUNT_NOT_ACTIVE',
      });
    }

    // 2. Validación de parámetros de entrada
    const requestData = request.data || {};
    const { dateString, timeSlot, reason } = requestData;
    const rawAction = requestData.action;
    const isUnblock = rawAction === 'UNBLOCK' || rawAction === 'DELETE' || requestData.active === false || requestData.remove === true;
    const action = isUnblock ? 'UNBLOCK' : 'BLOCK';

    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateString || typeof dateString !== 'string' || !dateRegex.test(dateString)) {
      throw new HttpsError('invalid-argument', 'El parámetro dateString es obligatorio y debe tener formato YYYY-MM-DD.', {
        errorCode: 'INVALID_DATE_FORMAT',
      });
    }

    const timeRegex = /^\d{2}:\d{2}$/;
    if (timeSlot !== undefined && timeSlot !== null && timeSlot !== '') {
      if (typeof timeSlot !== 'string' || !timeRegex.test(timeSlot)) {
        throw new HttpsError('invalid-argument', 'El parámetro timeSlot debe tener formato HH:mm.', {
          errorCode: 'INVALID_TIME_FORMAT',
        });
      }
    }

    const normalizedTimeSlot = (timeSlot && typeof timeSlot === 'string' && timeSlot.trim() !== '') ? timeSlot.trim() : null;
    const scope = normalizedTimeSlot ? 'SLOT' : 'DATE';
    const blockKey = scope === 'SLOT' ? `${dateString}_${normalizedTimeSlot}` : dateString;
    const blockRef = db.collection('availability_blocks').doc(blockKey);

    // 3. Ejecución según la acción solicitada
    if (action === 'BLOCK') {
      // --- BLOQUEAR (AG-06, ADR-004) ---
      // Aplicación incondicional: el bloqueo se crea siempre, sin fallar por ocupación previa
      await blockRef.set({
        scope,
        dateString,
        timeSlot: normalizedTimeSlot,
        reason: reason ? String(reason).trim().slice(0, 200) : null,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Consultar citas activas que colisionen con el intervalo bloqueado
      const appointmentsSnap = await db.collection('appointments')
        .where('dateString', '==', dateString)
        .get();

      const conflictingDocs = appointmentsSnap.docs.filter((doc) => {
        const data = doc.data();
        const isActive = data.status === 'PENDING' || data.status === 'CONFIRMED';
        if (!isActive) return false;
        if (scope === 'SLOT') {
          return data.timeSlot === normalizedTimeSlot;
        }
        return true;
      });

      // PROHIBICIÓN ESTRICTA DE CANCELACIÓN EN CADENA (ADR-004):
      // Ninguna cita cambia de estado a CANCELLED.
      // Se marca hasBlockConflict: true en lote (batch).
      if (conflictingDocs.length > 0) {
        const chunkSize = 500;
        for (let i = 0; i < conflictingDocs.length; i += chunkSize) {
          const chunk = conflictingDocs.slice(i, i + chunkSize);
          const batch = db.batch();
          for (const doc of chunk) {
            batch.update(doc.ref, {
              hasBlockConflict: true,
              'audit.updatedBy': uid,
              'audit.updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      }

      // Estructurar lista de conflictos para el panel de administración
      const conflicts = conflictingDocs.map((doc) => {
        const data = doc.data();
        return {
          appointmentId: doc.id,
          clientId: data.clientId,
          clientName: data.clientName || 'Cliente',
          petId: data.petId,
          petName: data.petName || 'Mascota',
          serviceId: data.serviceId,
          serviceName: data.serviceName || 'Servicio',
          dateString: data.dateString,
          timeSlot: data.timeSlot,
          status: data.status,
        };
      });

      // Trazabilidad en /audit_log (TRD §2.12, N-AD-08)
      await recordAuditLog(db, {
        actorUid: uid,
        actorName: request.auth.token?.name || 'Personal',
        actorRole: request.auth.token?.role || ROLES.ADMIN,
        action: 'SET_AVAILABILITY_BLOCK',
        targetType: 'AVAILABILITY_BLOCK',
        targetId: blockKey,
        metadata: {
          blockKey,
          scope,
          dateString,
          timeSlot: normalizedTimeSlot,
          reason: reason || null,
          conflictsCount: conflicts.length,
        },
      });

      return {
        success: true,
        action: 'BLOCK',
        blockKey,
        scope,
        dateString,
        timeSlot: normalizedTimeSlot,
        conflictsCount: conflicts.length,
        conflicts,
      };
    } else {
      // --- DESBLOQUEAR ---
      // Eliminar el documento de /availability_blocks
      await blockRef.delete();

      // Consultar citas activas que tengan hasBlockConflict: true
      const appointmentsSnap = await db.collection('appointments')
        .where('dateString', '==', dateString)
        .where('hasBlockConflict', '==', true)
        .get();

      const affectedDocs = appointmentsSnap.docs.filter((doc) => {
        const data = doc.data();
        const isActive = data.status === 'PENDING' || data.status === 'CONFIRMED';
        if (!isActive) return false;
        if (scope === 'SLOT') {
          return data.timeSlot === normalizedTimeSlot;
        }
        return true;
      });

      // Verificar si algún otro bloqueo persiste sobre cada cita
      const docsToClear = [];
      if (scope === 'SLOT') {
        const dateBlockDoc = await db.collection('availability_blocks').doc(dateString).get();
        if (!dateBlockDoc.exists) {
          docsToClear.push(...affectedDocs);
        }
      } else {
        // scope === 'DATE'
        for (const doc of affectedDocs) {
          const data = doc.data();
          const slotBlockDoc = await db.collection('availability_blocks').doc(`${dateString}_${data.timeSlot}`).get();
          if (!slotBlockDoc.exists) {
            docsToClear.push(doc);
          }
        }
      }

      // Apagar la marca hasBlockConflict: false en lote
      if (docsToClear.length > 0) {
        const chunkSize = 500;
        for (let i = 0; i < docsToClear.length; i += chunkSize) {
          const chunk = docsToClear.slice(i, i + chunkSize);
          const batch = db.batch();
          for (const doc of chunk) {
            batch.update(doc.ref, {
              hasBlockConflict: false,
              'audit.updatedBy': uid,
              'audit.updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      }

      // Trazabilidad en /audit_log (TRD §2.12, N-AD-08)
      await recordAuditLog(db, {
        actorUid: uid,
        actorName: request.auth.token?.name || 'Personal',
        actorRole: request.auth.token?.role || ROLES.ADMIN,
        action: 'REMOVE_AVAILABILITY_BLOCK',
        targetType: 'AVAILABILITY_BLOCK',
        targetId: blockKey,
        metadata: {
          blockKey,
          scope,
          dateString,
          timeSlot: normalizedTimeSlot,
          unmarkedCount: docsToClear.length,
        },
      });

      return {
        success: true,
        action: 'UNBLOCK',
        blockKey,
        scope,
        dateString,
        timeSlot: normalizedTimeSlot,
        unmarkedCount: docsToClear.length,
      };
    }
  }
);
