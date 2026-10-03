// functions/src/config/constants.js
// Constantes oficiales de infraestructura, seguridad y dominios de la aplicación

export const FIRESTORE_DATABASE_ID = 'petshopdev';

export const REGIONS = {
  FIRESTORE: 'us-east1',
  STORAGE: 'us-central1',
};

// Control de App Check: activo en producción, condicional en emulador local
export const ENFORCE_APP_CHECK = process.env.FUNCTIONS_EMULATOR === 'true' ? false : true;

// Configuración de entorno. Ningún valor propio de un despliegue vive en el código: se lee de
// variables de entorno, que Firebase carga desde functions/.env (plantilla: functions/.env.example).
// Nombres reservados por la plataforma (prefijos FIREBASE_, X_GOOGLE_, EXT_, etc.) no se usan.

// Transporte SMTP del despachador de correo. Aquí sólo vive configuración NO secreta:
// la clave se lee de Secret Manager mediante defineSecret('BREVO_SMTP_KEY') y se enlaza
// exclusivamente a la función despachadora.
export const SMTP_HOST = process.env.SMTP_HOST ?? '';
export const SMTP_PORT = 587; // STARTTLS
export const SMTP_USER = process.env.SMTP_USER ?? '';

// Remitente de los avisos por correo. Debe ser un remitente VERIFICADO en el proveedor SMTP:
// si no lo está, el proveedor rechaza el envío y el documento queda en delivery.state ERROR.
export const MAIL_FROM = process.env.MAIL_FROM ?? '';

// Claves de sitio de reCAPTCHA Enterprise (públicas por diseño, pero propias de cada despliegue).
export const RECAPTCHA_SCORE_SITE_KEY = process.env.RECAPTCHA_SCORE_SITE_KEY ?? ''; // clave de puntuación (invisible)
export const RECAPTCHA_CHECKBOX_SITE_KEY = process.env.RECAPTCHA_CHECKBOX_SITE_KEY ?? ''; // clave de casilla (visible)

// Bucket de Cloud Storage. Si se omite se usa el bucket por defecto del proyecto.
export const STORAGE_BUCKET = process.env.STORAGE_BUCKET ?? '';

// TTL de la prueba efímera de verificación de persona (2 minutos)
export const HUMAN_CHECK_TTL_MS = 2 * 60 * 1000;

// Roles del sistema (TRD §1.1, §4.1, §4.2)
export const ROLES = {
  CLIENT: 'CLIENT',
  ADMIN: 'ADMIN',
  SUPERADMIN: 'SUPERADMIN',
};

// Estados del usuario (TRD §1.1, §4.2)
export const USER_STATUS = {
  PENDING_PROFILE: 'PENDING_PROFILE',
  ACTIVE: 'ACTIVE',
  DEACTIVATED: 'DEACTIVATED',
  DELETED: 'DELETED',
};

// Límites numéricos de Etapa 2 (TRD §2.5, §3.2.B, N-11, AUD-149)
export const DAILY_APPOINTMENTS_LIMIT = 5;
export const APPOINTMENT_NOTES_MAX_LENGTH = 250;

// Límites numéricos de Etapa 3 (TRD §2.6, §2.8, §2.10, N-11, AUD-149)
export const DAILY_REQUESTS_LIMIT = 10;
export const PROFORMA_MAX_ITEMS = 100;
export const PROFORMA_VOID_REASON_MAX_LENGTH = 300;
export const PRODUCT_NAME_MAX_LENGTH = 80;
export const PROFORMA_DELIVERY_LEASE_MS = 60000;

// Límites numéricos de solicitudes de productos de Etapa 6 (PRD PR-04, ADR-023, WP-6.1)
// MAX_REQUEST_LINES: Viene taxativamente del PRD PR-04: «hasta 50 productos distintos».
export const MAX_REQUEST_LINES = 50;

// MAX_REQUEST_QUANTITY: Decisión de ingeniería (ADR-023). PR-04 fija el suelo y no fija techo.
export const MAX_REQUEST_QUANTITY = 99;

