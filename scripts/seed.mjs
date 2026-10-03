// scripts/seed.mjs
// Aprovisionamiento inicial normativo e idempotente de la Named Database petshopdev (TRD §1.5)

import { db, FieldValue } from '../functions/src/config/firebase.js';
import { ROLES } from '../functions/src/config/constants.js';

async function seedDocument(docRef, data, description) {
  const docSnap = await docRef.get();
  if (docSnap.exists) {
    console.log(`[IDEMPOTENT] Documento ya existe: ${docRef.path} (${description}) -> Sin cambios`);
    return false;
  }
  await docRef.set(data);
  console.log(`[CREATED] Documento creado: ${docRef.path} (${description})`);
  return true;
}

async function runSeed() {
  console.log('================================================================');
  console.log('[SEED] Ejecutando aprovisionamiento inicial sobre petshopdev...');
  console.log('================================================================');

  let createdCount = 0;
  let existingCount = 0;

  // 1. business_config/operating_parameters
  const operatingParamsRef = db.collection('business_config').doc('operating_parameters');
  const operatingParamsData = {
    openingTime: '08:00',
    closingTime: '18:00',
    slotDurationMinutes: 30,
    timezone: 'America/Guayaquil',
    workingWeekdays: [1, 2, 3, 4, 5, 6],
    lowStockThreshold: 5,
    audit: {
      updatedBy: 'SYSTEM_SEED',
      updatedAt: FieldValue.serverTimestamp(),
    },
  };
  (await seedDocument(operatingParamsRef, operatingParamsData, 'Parámetros operativos internos'))
    ? createdCount++
    : existingCount++;

  // 2. business_config/public_operating
  const publicOperatingRef = db.collection('business_config').doc('public_operating');
  const publicOperatingData = {
    openingTime: '08:00',
    closingTime: '18:00',
    slotDurationMinutes: 30,
    timezone: 'America/Guayaquil',
    workingWeekdays: [1, 2, 3, 4, 5, 6],
    updatedAt: FieldValue.serverTimestamp(),
  };
  (await seedDocument(publicOperatingRef, publicOperatingData, 'Réplica pública operativa'))
    ? createdCount++
    : existingCount++;

  // 3. business_config/billing_parameters
  const billingParamsRef = db.collection('business_config').doc('billing_parameters');
  const billingParamsData = {
    // Datos de ejemplo: sustitúyelos por los del negocio real desde el panel de administración.
    businessName: 'PetShop',
    taxId: '0000000000001',
    address: 'Calle Ejemplo 123',
    phone: '+593999999999',
    logoPath: 'media/business/logo.png',
    proformaSeries: '001-001',
    nextProformaNumber: 1,
    ivaBp: 1500, // 15% IVA vigente (CF-13)
    iceIncludedInIvaBase: true,
    deliveryLock: {
      holder: null,
      proformaId: null,
      leaseId: null,
      expiresAt: null,
    },
    audit: {
      updatedBy: 'SYSTEM_SEED',
      updatedAt: FieldValue.serverTimestamp(),
    },
  };
  (await seedDocument(billingParamsRef, billingParamsData, 'Parámetros de facturación internos'))
    ? createdCount++
    : existingCount++;

  // 4. business_config/public_pricing
  const publicPricingRef = db.collection('business_config').doc('public_pricing');
  const publicPricingData = {
    ivaBp: 1500,
    iceIncludedInIvaBase: true,
    updatedAt: FieldValue.serverTimestamp(),
  };
  (await seedDocument(publicPricingRef, publicPricingData, 'Réplica pública tributaria y precios'))
    ? createdCount++
    : existingCount++;

  // 5. mail_templates/appointment_cancelled
  const cancelledTemplateRef = db.collection('mail_templates').doc('appointment_cancelled');
  const cancelledTemplateData = {
    subject: 'Cancelación de Cita - PetShop',
    html: '<p>Estimado/a {{clientName}}, le informamos que la cita para {{petName}} programada para el {{fromDateString}} a las {{fromTimeSlot}} ha sido cancelada por {{actorName}}.</p>',
    text: 'Estimado/a {{clientName}}, le informamos que la cita para {{petName}} programada para el {{fromDateString}} a las {{fromTimeSlot}} ha sido cancelada por {{actorName}}.',
  };
  (await seedDocument(cancelledTemplateRef, cancelledTemplateData, 'Plantilla de cita cancelada'))
    ? createdCount++
    : existingCount++;

  // 6. mail_templates/appointment_rescheduled
  const rescheduledTemplateRef = db.collection('mail_templates').doc('appointment_rescheduled');
  const rescheduledTemplateData = {
    subject: 'Reprogramación de Cita - PetShop',
    html: '<p>Estimado/a {{clientName}}, su cita para {{petName}} ha sido reagendada del {{fromDateString}} {{fromTimeSlot}} al {{toDateString}} {{toTimeSlot}} por {{actorName}}.</p>',
    text: 'Estimado/a {{clientName}}, su cita para {{petName}} ha sido reagendada del {{fromDateString}} {{fromTimeSlot}} al {{toDateString}} {{toTimeSlot}} por {{actorName}}.',
  };
  (await seedDocument(rescheduledTemplateRef, rescheduledTemplateData, 'Plantilla de cita reprogramada'))
    ? createdCount++
    : existingCount++;

  // 7. chats/STAFF_INTERNAL + subdocumento read_states/{superadminUid}
  const staffChatRef = db.collection('chats').doc('STAFF_INTERNAL');
  const staffChatData = {
    id: 'STAFF_INTERNAL',
    type: 'STAFF_INTERNAL',
    clientId: null,
    clientName: null,
    clientSearchName: null,
    isArchived: false,
    staffUnreadCount: 0,
    lastMessageText: null,
    lastMessageTimestamp: null,
    lastMessageSenderName: null,
    messageCount: 0,
    updatedAt: FieldValue.serverTimestamp(),
  };
  (await seedDocument(staffChatRef, staffChatData, 'Canal interno del personal'))
    ? createdCount++
    : existingCount++;

  // Subdocumento de lectura para el Super Usuario en STAFF_INTERNAL
  let superadminUid = 'SUPERADMIN_INITIAL';
  try {
    const superAdminSnap = await db.collection('users')
      .where('role', '==', ROLES.SUPERADMIN)
      .limit(1)
      .get();
    if (!superAdminSnap.empty) {
      superadminUid = superAdminSnap.docs[0].id;
    }
  } catch (err) {
    console.log(`[WARN] No se pudo resolver UID de SUPERADMIN en /users (${err.message}). Usando identificador base.`);
  }

  const readStateRef = staffChatRef.collection('read_states').doc(superadminUid);
  const readStateData = {
    uid: superadminUid,
    lastReadAt: FieldValue.serverTimestamp(),
    unreadCount: 0,
  };
  await seedDocument(readStateRef, readStateData, `Estado de lectura inicial de ${superadminUid}`);

  console.log('================================================================');
  console.log(`[RESUMEN SEED] Documentos creados: ${createdCount} | Documentos ya existentes: ${existingCount}`);
  if (createdCount === 0) {
    console.log('[IDEMPOTENCIA VERIFICADA] El entorno ya contenía los documentos requeridos. Estado inalterado.');
  }
  console.log('================================================================');
}

runSeed().catch((error) => {
  console.error('[ERROR CRITICO] Falló la ejecución del seed:', error);
  process.exit(1);
});
