// functions/src/config/firebase.js
// Inicialización del Admin SDK anclado a la base de datos nombrada petshopdev

import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { FIRESTORE_DATABASE_ID, STORAGE_BUCKET } from './constants.js';

const app = getApps().length === 0 ? initializeApp() : getApps()[0];

// Instancia de Firestore anclada a la Named Database 'petshopdev'
export const db = getFirestore(app, FIRESTORE_DATABASE_ID);

// Instancia de Auth del Admin SDK
export const auth = getAuth(app);

// Bucket de Cloud Storage: el indicado en STORAGE_BUCKET o, si falta, el bucket por defecto del proyecto.
// Se resuelve de forma DIFERIDA (al primer uso): importar este módulo desde un script de Node
// (scripts/seed.mjs, scripts/provision-superadmin.mjs), que no usa Storage, no debe fallar por no
// tener un bucket configurado.
let cachedBucket = null;
function resolveBucket() {
  if (cachedBucket) return cachedBucket;
  try {
    cachedBucket = STORAGE_BUCKET ? getStorage(app).bucket(STORAGE_BUCKET) : getStorage(app).bucket();
    return cachedBucket;
  } catch (err) {
    throw new Error(
      'No se pudo determinar el bucket de Cloud Storage. Define STORAGE_BUCKET: en functions/.env si ' +
      'ejecutas con la Firebase CLI (ver functions/.env.example) o como variable de entorno si ejecutas ' +
      `un script (STORAGE_BUCKET=<proyecto>.firebasestorage.app node scripts/...). Detalle: ${err.message}`
    );
  }
}
export const storage = new Proxy({}, {
  get(_target, prop) {
    // `then` y los símbolos los consulta el propio motor (promesas, inspección): no deben resolver el bucket.
    if (prop === 'then' || typeof prop === 'symbol') return undefined;
    const bucket = resolveBucket();
    const value = bucket[prop];
    return typeof value === 'function' ? value.bind(bucket) : value;
  },
});

export { FieldValue, Timestamp };
