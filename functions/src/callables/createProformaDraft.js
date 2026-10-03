// functions/src/callables/createProformaDraft.js
// Callable de creación de borrador de proforma por personal (TRD §3.3.B, §2.10, FA-03, CA-AD-41)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue } from 'firebase-admin/firestore';
import { db, auth } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import { PROFORMA_STATUS } from '../domain/proforma.js';

export const createProformaDraft = onCall(
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

    // Verificación de revocación de token si viene en cabeceras
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

    // 2. Validación de argumentos
    const requestData = request.data || {};
    const { clientId } = requestData;

    if (!clientId || typeof clientId !== 'string' || clientId.trim() === '') {
      throw new HttpsError('invalid-argument', 'El identificador del cliente (clientId) es obligatorio.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedClientId = clientId.trim();

    // Validar existencia del cliente
    const clientDoc = await db.collection('users').doc(trimmedClientId).get();
    if (!clientDoc.exists) {
      throw new HttpsError('not-found', 'Cliente no encontrado.', {
        errorCode: 'NOT_FOUND',
      });
    }

    const proformaRef = db.collection('proformas').doc();
    const proformaId = proformaRef.id;

    // 3. Creación del documento en DRAFT (TRD §2.10, FA-03, FA-05 punto 3)
    // Invariante: Un borrador no congela identidad ni precios y no cierra ventanas de cancelación.
    // clientSnapshot y businessSnapshot se inicializan en null (se congelan en la ENTREGA).
    const newProforma = {
      id: proformaId,
      series: null,
      number: null,
      formattedNumber: null,
      clientId: trimmedClientId,
      clientSnapshot: null,
      businessSnapshot: null,
      status: PROFORMA_STATUS.DRAFT,
      items: [],
      adjustments: [],
      subtotalCents: 0,
      totalDiscountCents: 0,
      totalSurchargeCents: 0,
      taxableBaseCents: 0,
      totalIceCents: 0,
      totalIvaCents: 0,
      totalCents: 0,
      iceIncludedInIvaBase: null,
      pdfPath: null,
      voidReason: null,
      createdAt: FieldValue.serverTimestamp(),
      deliveredAt: null,
      finalizedAt: null,
      voidedAt: null,
      audit: {
        createdBy: uid,
        deliveredBy: null,
        finalizedBy: null,
        voidedBy: null,
        updatedBy: uid,
        updatedAt: FieldValue.serverTimestamp(),
      },
    };

    await proformaRef.set(newProforma);

    return {
      success: true,
      proformaId,
      status: PROFORMA_STATUS.DRAFT,
      clientId: trimmedClientId,
    };
  }
);
