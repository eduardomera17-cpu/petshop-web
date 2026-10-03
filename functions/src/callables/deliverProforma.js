// functions/src/callables/deliverProforma.js
// Callable de entrega indivisible de proforma en tres fases con cerrojo y compensación (D-T4, TRD §3.3.E, §8.2, FA-05, FA-09)

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import crypto from 'node:crypto';
import { db, auth, storage } from '../config/firebase.js';
import { REGIONS, ROLES, USER_STATUS, PROFORMA_DELIVERY_LEASE_MS, ENFORCE_APP_CHECK } from '../config/constants.js';
import { assertRole } from '../domain/guards.js';
import {
  PROFORMA_STATUS,
  recalculateProformaDocument,
} from '../domain/proforma.js';
import { generateProformaPdf } from '../lib/proforma_pdf.js';
import { recordAuditLog } from '../lib/audit.js';

export const deliverProforma = onCall(
  {
    enforceAppCheck: ENFORCE_APP_CHECK,
    region: REGIONS.FIRESTORE,
    memory: '1GiB',
    timeoutSeconds: 120, // TRD §8.2 S-2
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

    const requestData = request.data || {};
    const { proformaId, requestId } = requestData;

    // Idempotencia por requestId sobre /idempotency/{requestId} (TRD §3.7)
    if (requestId && typeof requestId === 'string' && requestId.trim() !== '') {
      const idempotencyDoc = await db.collection('idempotency').doc(requestId.trim()).get();
      if (idempotencyDoc.exists) {
        return idempotencyDoc.data()?.response;
      }
    }

    if (!proformaId || typeof proformaId !== 'string' || proformaId.trim() === '') {
      throw new HttpsError('invalid-argument', 'proformaId es obligatorio y debe ser texto no vacío.', {
        errorCode: 'INVALID_ARGUMENT',
      });
    }

    const trimmedProformaId = proformaId.trim();
    const proformaRef = db.collection('proformas').doc(trimmedProformaId);
    const billingRef = db.collection('business_config').doc('billing_parameters');

    let leaseId = null;
    let pdfUploaded = false;
    let pdfPath = null;
    let phase1Result = null;

    try {
      // ══════════════════════════════════════════════════════════════════════════
      // FASE 1: Transacción T1 (Reserva Atómica de Arrendamiento y Snapshots)
      // Regla Firestore: TODAS las lecturas se ejecutan antes de CUALQUIER escritura.
      // ══════════════════════════════════════════════════════════════════════════
      phase1Result = await db.runTransaction(async (transaction) => {
        // --- LECTURAS ---
        // 1.1. Leer /proformas/{id}
        const proformaDoc = await transaction.get(proformaRef);
        if (!proformaDoc.exists) {
          throw new HttpsError('not-found', 'Proforma no encontrada.', {
            errorCode: 'NOT_FOUND',
          });
        }

        const proformaData = proformaDoc.data();
        if (proformaData.status !== PROFORMA_STATUS.DRAFT) {
          throw new HttpsError('failed-precondition', 'La proforma no está en estado DRAFT.', {
            errorCode: 'PROFORMA_NOT_DRAFT',
          });
        }

        const items = Array.isArray(proformaData.items) ? proformaData.items : [];
        if (items.length === 0) {
          throw new HttpsError('failed-precondition', 'La proforma no contiene conceptos y no puede ser entregada.', {
            errorCode: 'PROFORMA_EMPTY',
          });
        }

        // 1.2. Leer cada concepto referenciado
        const conceptDocs = [];
        for (const item of items) {
          if (item.itemType === 'SERVICE') {
            const aptDoc = await transaction.get(db.collection('appointments').doc(item.refId));
            conceptDocs.push({ item, doc: aptDoc });
          } else if (item.itemType === 'PRODUCT') {
            const reqDoc = await transaction.get(db.collection('product_requests').doc(item.refId));
            conceptDocs.push({ item, doc: reqDoc });
          }
        }

        // 1.3. Leer /business_config/billing_parameters
        const billingDoc = await transaction.get(billingRef);
        if (!billingDoc.exists) {
          throw new HttpsError('failed-precondition', 'Configuración de facturación no disponible.', {
            errorCode: 'CONFIG_UNAVAILABLE',
          });
        }

        // 1.4. Leer /users/{clientId}
        const clientDoc = await transaction.get(db.collection('users').doc(proformaData.clientId));

        // --- VALIDACIONES Y COMPUTACIÓN (sin escrituras todavía) ---
        // Validar conceptos leídos
        for (const { item, doc } of conceptDocs) {
          if (!doc.exists) {
            throw new HttpsError('aborted', `El concepto ${item.refId} ya no existe.`, {
              errorCode: 'CONCEPT_NO_LONGER_VALID',
            });
          }
          const docData = doc.data();
          if (item.itemType === 'SERVICE') {
            if (docData.status !== 'COMPLETED' || docData.isBilled === true || docData.proformaId !== trimmedProformaId) {
              throw new HttpsError('aborted', `La cita ${item.refId} ya no es válida o fue alterada.`, {
                errorCode: 'CONCEPT_NO_LONGER_VALID',
              });
            }
          } else if (item.itemType === 'PRODUCT') {
            if (docData.status !== 'READY_FOR_PICKUP' || docData.proformaId !== trimmedProformaId) {
              throw new HttpsError('aborted', `La solicitud ${item.refId} ya no es válida o fue cancelada.`, {
                errorCode: 'CONCEPT_NO_LONGER_VALID',
              });
            }
          }
        }

        // Validar cerrojo deliveryLock
        const billingData = billingDoc.data();
        const currentLock = billingData.deliveryLock;
        const nowMs = Date.now();

        const lockExpiresAtMs = currentLock?.expiresAt
          ? (typeof currentLock.expiresAt.toMillis === 'function'
              ? currentLock.expiresAt.toMillis()
              : (currentLock.expiresAt.seconds != null
                  ? currentLock.expiresAt.seconds * 1000
                  : (currentLock.expiresAt._seconds != null
                      ? currentLock.expiresAt._seconds * 1000
                      : (currentLock.expiresAt instanceof Date ? currentLock.expiresAt.getTime() : Number(currentLock.expiresAt)))))
          : 0;

        if (
          currentLock &&
          currentLock.holder != null &&
          lockExpiresAtMs > nowMs
        ) {
          throw new HttpsError('aborted', 'Existe otra entrega de proforma en curso.', {
            errorCode: 'DELIVERY_IN_PROGRESS',
          });
        }

        const myLeaseId = crypto.randomUUID();
        const expiresAt = Timestamp.fromMillis(nowMs + PROFORMA_DELIVERY_LEASE_MS);

        // Lectura del Correlativo N (SE LEE, NO SE INCREMENTA EN T1)
        const N = typeof billingData.nextProformaNumber === 'number' ? billingData.nextProformaNumber : 1;
        const series = billingData.proformaSeries || '001-001';

        // Componer snapshots
        const clientData = clientDoc.exists ? clientDoc.data() : {};
        const clientSnapshot = {
          fullName: clientData.fullName || 'Consumidor Final',
          documentType: clientData.documentType || 'CEDULA',
          documentNumber: clientData.documentNumber || '9999999999',
          address: clientData.address || '',
          phone: clientData.phone || '',
          email: clientData.email || '',
        };

        const businessSnapshot = {
          businessName: billingData.businessName || 'PetShop',
          taxId: billingData.taxId || '',
          address: billingData.address || '',
          phone: billingData.phone || '',
          logoPath: billingData.logoPath || null,
        };

        // ADR-016 y caso crítico 23 (AUD-326): manda la regla congelada con la proforma.
        // Entre la composición y la entrega puede haber cambiado CF-13; el documento no.
        const iceIncludedInIvaBase = typeof proformaData.iceIncludedInIvaBase === 'boolean'
          ? proformaData.iceIncludedInIvaBase
          : (typeof billingData.iceIncludedInIvaBase === 'boolean'
            ? billingData.iceIncludedInIvaBase
            : true);

        const calculatedTotals = recalculateProformaDocument({
          items: items,
          adjustments: proformaData.adjustments || [],
          iceIncludedInIvaBase,
        });

        // --- ESCRITURAS ---
        transaction.update(billingRef, {
          deliveryLock: {
            holder: uid,
            proformaId: trimmedProformaId,
            leaseId: myLeaseId,
            expiresAt: expiresAt,
          },
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          N,
          series,
          leaseId: myLeaseId,
          items: calculatedTotals.items,
          adjustments: calculatedTotals.adjustments,
          totals: calculatedTotals,
          clientSnapshot,
          businessSnapshot,
          clientId: proformaData.clientId,
          iceIncludedInIvaBase,
        };
      });

      leaseId = phase1Result.leaseId;
      const { N, series, clientId, clientSnapshot, businessSnapshot, items, adjustments, totals, iceIncludedInIvaBase } = phase1Result;

      // ══════════════════════════════════════════════════════════════════════════
      // FASE 2: Fuera de Transacción (Composición y Carga de PDF)
      // ══════════════════════════════════════════════════════════════════════════
      const formattedNumber = `${series}-${N}`;
      pdfPath = `proformas/${clientId}/${series}-${N}.pdf`;

      // Intentar obtener buffer de logotipo si existe en Storage
      let logoBuffer = null;
      if (businessSnapshot.logoPath && typeof businessSnapshot.logoPath === 'string') {
        try {
          const [buf] = await storage.file(businessSnapshot.logoPath).download();
          logoBuffer = buf;
        } catch (logoErr) {
          console.warn('[deliverProforma] Logotipo no disponible en Storage, componiendo sin logo:', logoErr.message);
          logoBuffer = null;
        }
      }

      // Componer PDF en memoria
      const pdfBuffer = await generateProformaPdf({
        series,
        number: N,
        formattedNumber,
        proformaId: trimmedProformaId,
        items,
        adjustments,
        totals,
        clientSnapshot,
        businessSnapshot,
        logoBuffer,
      });

      // Subir buffer a Cloud Storage
      const destinationFile = storage.file(pdfPath);
      await destinationFile.save(pdfBuffer, {
        contentType: 'application/pdf',
        metadata: {
          contentType: 'application/pdf',
          metadata: {
            proformaId: trimmedProformaId,
            clientId,
            deliveredBy: uid,
          },
        },
      });
      pdfUploaded = true;

      // ══════════════════════════════════════════════════════════════════════════
      // FASE 3: Transacción T2 (Consumo de Número, Estado y Liberación)
      // Regla Firestore: TODAS las lecturas se ejecutan antes de CUALQUIER escritura.
      // ══════════════════════════════════════════════════════════════════════════
      let finalResponsePayload = null;

      await db.runTransaction(async (transaction) => {
        // --- LECTURAS ---
        const proformaDoc = await transaction.get(proformaRef);
        const billingDoc = await transaction.get(billingRef);

        // --- VALIDACIONES ---
        if (!proformaDoc.exists || proformaDoc.data()?.status !== PROFORMA_STATUS.DRAFT) {
          throw new HttpsError('failed-precondition', 'La proforma ya no está en estado DRAFT.', {
            errorCode: 'PROFORMA_NOT_DRAFT',
          });
        }

        const billingData = billingDoc.data() || {};
        const lock = billingData.deliveryLock;
        const nowMs = Date.now();

        const isLockValid =
          lock &&
          lock.holder === uid &&
          lock.proformaId === trimmedProformaId &&
          lock.leaseId === leaseId &&
          lock.expiresAt &&
          lock.expiresAt.toMillis() >= nowMs;

        if (!isLockValid) {
          throw new HttpsError('aborted', 'El arrendamiento de entrega ha expirado o fue tomado por otro proceso.', {
            errorCode: 'DELIVERY_LEASE_LOST',
          });
        }

        // --- ESCRITURAS ---
        // 3.3. Persistir proforma en estado DELIVERED
        transaction.update(proformaRef, {
          status: PROFORMA_STATUS.DELIVERED,
          series,
          number: N,
          formattedNumber,
          items,
          adjustments,
          subtotalCents: totals.subtotalCents,
          totalDiscountCents: totals.totalDiscountCents,
          totalSurchargeCents: totals.totalSurchargeCents,
          taxableBaseCents: totals.taxableBaseCents,
          totalIceCents: totals.totalIceCents,
          totalIvaCents: totals.totalIvaCents,
          totalCents: totals.totalCents,
          iceIncludedInIvaBase,
          clientSnapshot,
          businessSnapshot,
          pdfPath,
          deliveredAt: FieldValue.serverTimestamp(),
          'audit.deliveredBy': uid,
          'audit.deliveredAt': FieldValue.serverTimestamp(),
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });

        // 3.4. Consumo del Correlativo: nextProformaNumber = N + 1 y liberación de lock
        transaction.update(billingRef, {
          nextProformaNumber: N + 1,
          deliveryLock: {
            holder: null,
            proformaId: null,
            leaseId: null,
            expiresAt: null,
          },
          'audit.updatedBy': uid,
          'audit.updatedAt': FieldValue.serverTimestamp(),
        });

        // 3.5. Registro en /audit_log (TRD §2.12, N-AD-08)
        recordAuditLog(transaction, {
          actorUid: uid,
          actorName: token.name || 'Personal',
          actorRole: token.role || ROLES.ADMIN,
          action: 'PROFORMA_DELIVER',
          targetType: 'PROFORMA',
          targetId: trimmedProformaId,
          metadata: {
            proformaId: trimmedProformaId,
            formattedNumber,
            clientId,
            number: N,
            series,
            totalCents: totals.totalCents,
            pdfPath,
          },
        });

        finalResponsePayload = {
          success: true,
          proformaId: trimmedProformaId,
          status: PROFORMA_STATUS.DELIVERED,
          series,
          number: N,
          formattedNumber,
          pdfPath,
          totalCents: totals.totalCents,
        };

        // Si se proporcionó requestId de idempotencia, registrar resultado
        if (requestId && typeof requestId === 'string' && requestId.trim() !== '') {
          const idempotencyRef = db.collection('idempotency').doc(requestId.trim());
          transaction.set(idempotencyRef, {
            requestId: requestId.trim(),
            userId: uid,
            action: 'deliverProforma',
            response: finalResponsePayload,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
      });

      return finalResponsePayload;
    } catch (error) {
      // ══════════════════════════════════════════════════════════════════════════
      // MECANISMO DE COMPENSACIÓN (Ante cualquier fallo en Fase 2 o 3)
      // ══════════════════════════════════════════════════════════════════════════
      try {
        if (leaseId) {
          const billingDoc = await db.collection('business_config').doc('billing_parameters').get();
          if (billingDoc.exists) {
            const currentLock = billingDoc.data()?.deliveryLock;
            // Solo si el leaseId actual coincide con el de este proceso
            if (currentLock?.leaseId === leaseId) {
              if (pdfUploaded && pdfPath) {
                await storage.file(pdfPath).delete({ ignoreNotFound: true }).catch((delErr) => {
                  console.warn('[deliverProforma Compensation] Error al borrar archivo en Storage:', delErr.message);
                });
              }
              await db.collection('business_config').doc('billing_parameters').update({
                deliveryLock: {
                  holder: null,
                  proformaId: null,
                  leaseId: null,
                  expiresAt: null,
                },
                'audit.updatedBy': uid,
                'audit.updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              console.warn('[deliverProforma Compensation] leaseId ya no coincide; se omite compensación.');
            }
          }
        }
      } catch (compErr) {
        console.error('[deliverProforma Compensation] Error al ejecutar compensación:', compErr);
      }

      throw error;
    }
  }
);
