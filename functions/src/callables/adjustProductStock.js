// functions/src/callables/adjustProductStock.js
// Callable de ajuste manual de inventario con delta con signo (TRD §3.2.J, IN-01, IN-02, CA-AD-11, AUD-026, AUD-149, N-AD-08)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { recordAuditLog } from '../lib/audit.js';

export const adjustProductStock = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
  },
  async (request) => {
    // 1. Verificación de autenticación y rol de personal (ADMIN o SUPERADMIN)
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError('unauthenticated', 'Usuario no autenticado.', {
        errorCode: 'UNAUTHENTICATED',
      });
    }

    assertRole(request.auth, [ROLES.ADMIN, ROLES.SUPERADMIN]);

    // Verificación de revocación y estado activo (TRD §4.2, §4.6)
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

    // 2. Validación de argumentos (productId y delta relativo con signo)
    const data = request.data || {};
    const { productId, delta } = data;

    if (!productId || typeof productId !== 'string' || productId.trim() === '') {
      throw new HttpsError('invalid-argument', 'productId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    if (typeof delta !== 'number' || !Number.isInteger(delta) || delta === 0) {
      throw new HttpsError(
        'invalid-argument',
        'delta es obligatorio, debe ser un entero distinto de cero.',
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    // Prohibición estricta: Rechazar cualquier intento de enviar stock absoluto
    if ('stock' in data || 'newStock' in data || 'absoluteStock' in data) {
      throw new HttpsError(
        'invalid-argument',
        'El ajuste manual de inventario sólo admite incremento relativo con signo (delta). Prohibido valor absoluto.',
        { errorCode: 'INVALID_ARGUMENT' }
      );
    }

    const trimmedProductId = productId.trim();
    const productRef = db.collection('products').doc(trimmedProductId);
    const auditRef = db.collection('audit_log').doc();

    let actorName = token.name || 'Personal';
    const actorRole = token.role || ROLES.ADMIN;

    // Obtener nombre del usuario si no viene en token
    if (!token.name) {
      try {
        const userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data()?.fullName) {
          actorName = userDoc.data().fullName;
        }
      } catch {
        // Fallback a Personal
      }
    }

    let finalStock = 0;

    // 3. Transacción atómica de ajuste de stock (TRD §3.2.J)
    await db.runTransaction(async (transaction) => {
      const productDoc = await transaction.get(productRef);
      if (!productDoc.exists) {
        throw new HttpsError('not-found', 'Producto no encontrado.', {
          errorCode: 'NOT_FOUND',
        });
      }

      const productData = productDoc.data();
      const currentStock = typeof productData.stock === 'number' ? productData.stock : 0;
      const resultingStock = currentStock + delta;

      // Validación de no negatividad
      if (resultingStock < 0) {
        throw new HttpsError(
          'failed-precondition',
          'El ajuste dejaría el stock en negativo.',
          { errorCode: 'INVALID_STOCK_ADJUSTMENT' }
        );
      }

      finalStock = resultingStock;

      // Mutación atómica en /products con FieldValue.increment(delta)
      transaction.update(productRef, {
        stock: FieldValue.increment(delta),
        'audit.updatedBy': uid,
        'audit.updatedAt': FieldValue.serverTimestamp(),
      });

      // Escritura atómica en /audit_log mediante Admin SDK (cierre denegar-todo, §2.12, N-AD-08)
      recordAuditLog(transaction, {
        docRef: auditRef,
        actorUid: uid,
        actorName,
        actorRole,
        action: 'PRODUCT_STOCK_ADJUST',
        targetType: 'PRODUCT',
        targetId: trimmedProductId,
        extraFields: {
          delta,
          resultingStock,
        },
        metadata: {
          previousStock: currentStock,
          delta,
          resultingStock,
        },
      });
    });

    return {
      success: true,
      productId: trimmedProductId,
      delta,
      resultingStock: finalStock,
      auditLogId: auditRef.id,
    };
  }
);
