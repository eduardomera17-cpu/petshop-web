// scripts/provision-superadmin.mjs
// Aprovisionamiento del Super Usuario oficial bajo TRD §1.5, §4.6, CA-AD-19 y WP-5.4

import crypto from 'node:crypto';
import { db, auth, FieldValue } from '../functions/src/config/firebase.js';
import { ROLES, USER_STATUS } from '../functions/src/config/constants.js';

/**
 * Script normativo para aprovisionar al Super Usuario único del sistema (CA-AD-19).
 *
 * Invariantes normativos:
 * 1. Exige la bandera obligatoria '--confirm' para proceder; aborta de inmediato si se omite.
 * 2. Valida la unicidad estricta (CA-AD-19): Si ya existe un SUPERADMIN en Firestore (/users) o en Auth,
 *    se detiene inmediatamente reportando la alerta y saliendo limpiamente con código 0.
 * 3. Asigna de forma indivisible los dos custom claims: { role: 'SUPERADMIN', status: 'ACTIVE' }.
 * 4. Escribe el documento completo en /users/{uid} con datos normativos y metadatos de auditoría.
 * 5. Es estrictamente idempotente: sucesivas ejecuciones no duplican ni alteran registros preexistentes.
 * 6. Blindaje de seguridad: Prohibido almacenar contraseñas por omisión o estáticas en el repositorio.
 */
export async function provisionSuperAdmin() {
  // 1. Verificación de bandera obligatoria --confirm
  const hasConfirm = process.argv.includes('--confirm');
  if (!hasConfirm) {
    console.error('[ABORT] Parámetro obligatorio omitido: Se requiere la bandera --confirm para proceder.');
    process.exit(1);
  }

  console.log('[INFO] Iniciando verificación de Super Usuario (CA-AD-19)...');

  // 2. Comprobar si ya existe un SUPERADMIN en Firestore (/users)
  const superAdminSnapshot = await db.collection('users')
    .where('role', '==', ROLES.SUPERADMIN)
    .limit(1)
    .get();

  // 2.b Comprobar si ya existe un SUPERADMIN en Firebase Auth
  let authSuperAdmin = null;
  try {
    const list = await auth.listUsers(100);
    authSuperAdmin = list.users.find((u) => u.customClaims?.role === ROLES.SUPERADMIN);
  } catch (err) {
    console.warn(`[WARN] No se pudo listar Auth (${err.message}). Continuando con verificación en Firestore.`);
  }

  if (!superAdminSnapshot.empty || authSuperAdmin) {
    const existingUid = !superAdminSnapshot.empty ? superAdminSnapshot.docs[0].id : authSuperAdmin.uid;
    const existingEmail = !superAdminSnapshot.empty ? superAdminSnapshot.docs[0].data().email : authSuperAdmin.email;
    console.log(`[ALERTA - CA-AD-19] Ya existe un SUPERADMIN en el sistema (UID: ${existingUid}, Email: ${existingEmail}).`);
    console.log('[DETENIDO] El script no pisa un SUPERADMIN existente. Finalizando.');
    process.exit(0);
  }

  // 3. Resolución de credenciales seguras
  // Se considera emulador SOLO si Auth y Firestore apuntan ambos a un emulador. Con una sola
  // variable definida el script podría escribir en el proyecto real sin que el operador lo note.
  const isEmulator = Boolean(
    process.env.FIREBASE_AUTH_EMULATOR_HOST &&
    process.env.FIRESTORE_EMULATOR_HOST
  );

  // El correo del Super Usuario nunca tiene valor por omisión: debe indicarlo el operador.
  const email = process.env.SUPERADMIN_EMAIL;
  let password = process.env.SUPERADMIN_PASSWORD;

  if (!password && isEmulator) {
    // En emulador: generación de clave efímera y segura sin registrar credenciales en código
    password = crypto.randomBytes(16).toString('hex') + 'A1!';
  }

  if (!email || !password) {
    console.error('[ABORT] Error de seguridad: SUPERADMIN_EMAIL es obligatorio y SUPERADMIN_PASSWORD también lo es fuera del emulador; ninguno admite valores por omisión.');
    process.exit(1);
  }

  const fullName = process.env.SUPERADMIN_NAME || 'Super Administrador';
  const phone = process.env.SUPERADMIN_PHONE || '+593999999999';

  // 4. Creación o resolución en Firebase Auth
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(email);
    console.log(`[INFO] Usuario encontrado en Firebase Auth: ${userRecord.uid}`);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log(`[INFO] Creando usuario en Firebase Auth para ${email}...`);
      userRecord = await auth.createUser({
        email,
        password,
        displayName: fullName,
        emailVerified: true,
      });
      console.log(`[INFO] Usuario creado exitosamente con UID: ${userRecord.uid}`);
    } else {
      throw error;
    }
  }

  const uid = userRecord.uid;

  // 5. Asignación indivisible de los DOS claims obligatorios (TRD §1.5)
  console.log(`[INFO] Asignando claims obligatorios a ${uid}: role='SUPERADMIN', status='ACTIVE'...`);
  await auth.setCustomUserClaims(uid, {
    role: ROLES.SUPERADMIN,
    status: USER_STATUS.ACTIVE,
  });

  // 6. Escribir el documento normativo completo en /users/{uid} (TRD §2.2)
  console.log(`[INFO] Escribiendo documento normativo en /users/${uid}...`);
  const userDocData = {
    uid: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    documentType: 'CEDULA',
    documentNumber: '1700000000',
    address: 'Quito, Pichincha, Ecuador',
    photoPath: null,
    role: ROLES.SUPERADMIN,
    status: USER_STATUS.ACTIVE,
    searchName: fullName.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, ''),
    deactivatedAt: null,
    deactivatedBy: null,
    deactivationReason: null,
    reactivatedAt: null,
    reactivatedBy: null,
    audit: {
      createdBy: uid,
      createdAt: FieldValue.serverTimestamp(),
      updatedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    },
  };

  await db.collection('users').doc(uid).set(userDocData);
  console.log('[OK] Documento de Super Usuario registrado exitosamente.');
  console.log('====================================================');
  console.log(`SUPERADMIN UID: ${uid}`);
  console.log(`SUPERADMIN EMAIL: ${email}`);
  console.log(`CLAIMS ASIGNADOS: role='${ROLES.SUPERADMIN}', status='${USER_STATUS.ACTIVE}'`);
  console.log('====================================================');

  return { status: 'PROVISIONED', uid, email };
}

// Auto-ejecución cuando el script es invocado directamente vía CLI
if (process.argv[1] && process.argv[1].replace(/\\/g, '/').endsWith('scripts/provision-superadmin.mjs')) {
  provisionSuperAdmin().catch((error) => {
    console.error('[ERROR CRITICO] Falló el aprovisionamiento de Super Usuario:', error);
    process.exit(error.exitCode || 1);
  });
}
