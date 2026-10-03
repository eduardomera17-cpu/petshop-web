# 📊 INFORME DE AUDITORÍA DE SEGURIDAD — PETSHOP

- **Proyecto:** PetShop (Flutter Web + Firebase + Node.js Cloud Functions)
- **Repositorio:** `eduardomera17-cpu/petshop-web` (rama auditada: `claude/trusting-hypatia-qs3uxk`, 1 commit: *Publicación inicial bajo GPL-3.0-or-later*)
- **Producción:** https://aplicacion-web-petshop.firebaseapp.com
- **Fecha:** 2026-10-03
- **Alcance:** SAST del repositorio completo (285 archivos), reglas de Firestore/Storage, 36 Cloud Functions callables + 10 triggers, cliente Flutter, scripts de aprovisionamiento, historial de git, dependencias (npm + pub), y comprobaciones **pasivas y no intrusivas** contra producción (cabeceras, CORS, reglas de acceso anónimo). No se ejecutaron exploits.

> **Nota metodológica (validación con información oficial):** cada hallazgo se contrastó con documentación oficial de Firebase, Google Cloud, Flutter, OWASP, NIST y MITRE CWE. Las referencias están al final.

---

## Resumen Ejecutivo

El proyecto presenta una **postura de seguridad muy por encima de la media** para un trabajo de titulación. La arquitectura aplica correctamente *defensa en profundidad*: reglas de seguridad en modo *denegar por defecto* con validación campo a campo, escritura de negocio canalizada exclusivamente por Cloud Functions transaccionales, App Check obligatorio, reCAPTCHA Enterprise, cabeceras HTTP y CSP estrictas, verificación de revocación de tokens en mutaciones, bitácora de auditoría con saneamiento de datos clínicos/PII, y externalización completa de secretos.

**No se encontraron credenciales expuestas, ni en el código ni en el historial de git.** No se hallaron vulnerabilidades críticas ni altas explotables.

| Severidad | Cantidad |
|---|---|
| 🔴 Crítica | 0 |
| 🟠 Alta | 0 |
| 🟡 Media | 2 |
| 🟢 Baja | 5 |
| ⚪ Informativa | 5 |

**Nivel de riesgo general: BAJO.** Los hallazgos son endurecimientos y mejoras de completitud, no fallos explotables de impacto directo. Las dos medias (política de contraseñas y persistencia de la sesión tras la desactivación) son configuraciones/decisiones de diseño que conviene cerrar antes de un uso con datos reales.

### Fortalezas verificadas (lo que ya está bien hecho)

- ✅ **Sin secretos hardcodeados.** Config del cliente por `--dart-define`, secretos SMTP en Secret Manager (`defineSecret('BREVO_SMTP_KEY')`), `.gitignore` cubre `.env`, `config/app_config.json`, `.firebaserc`, cuentas de servicio, `*.pem/*.key`, exportaciones de Auth y tokens de depuración de App Check. El escaneo del historial completo de git (285 blobs) y `detect-secrets` solo arrojaron cadenas de UI y los dominios públicos del proyecto.
- ✅ **Firestore/Storage en *deny-by-default*** (`match /{document=**} { allow read, write: if false; }`), con validación de tipos, tamaños, enums y `hasOnly()` para impedir inyección de campos arbitrarios. Verificado en producción: todo acceso anónimo a `petshopdev` devuelve `403 PERMISSION_DENIED`.
- ✅ **IDOR mitigado**: las callables devuelven `NOT_FOUND` (no `PERMISSION_DENIED`) ante recursos ajenos, evitando enumeración, y validan `ownerId/clientId == uid` dentro de transacción.
- ✅ **App Check obligatorio** en las 36 callables (`enforceAppCheck`), reCAPTCHA Enterprise, y verificación de revocación de token (`verifyIdToken(idToken, true)`) en las mutaciones sensibles.
- ✅ **Datos clínicos confidenciales**: el cliente nunca lee ni escribe `clinical_records`; la bitácora `audit_log` sanea claves clínicas/financieras y texto de chat.
- ✅ **Pipeline de imágenes** re-codifica con `sharp`, **elimina metadatos EXIF/geolocalización**, limita a 5 MB y bloquea SVG/HEIC.
- ✅ **Cabeceras HTTP**: HSTS con `preload`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, CSP con `object-src 'none'` y `frame-ancestors 'none'`, COOP/CORP y `Permissions-Policy` restrictiva.
- ✅ **`npm audit` sin vulnerabilidades** (0 en 314 dependencias) y dependencias en versiones recientes.

---

## 🔴 Vulnerabilidades Críticas

**Ninguna.**

---

## 🟠 Vulnerabilidades Altas

**Ninguna.**

---

## 🟡 Vulnerabilidades Medias

### M-01 — Política de contraseñas débil y ausencia de MFA (CWE-521, CWE-308)

- **Ubicación:** `lib/ui/features/auth/view_models/register_view_model.dart:125`; `lib/ui/features/auth/view_models/change_password_view_model.dart:64,107`. Configuración de Firebase Authentication (consola del proyecto).
- **Descripción:** La única exigencia de contraseña es longitud `< 6` en el cliente. No hay política de complejidad ni validación de longitud en servidor, y no se observa configurado el *password policy* de Identity Platform ni MFA/TOTP. Al tratarse de validación de cliente, es eludible llamando directamente a la API de Authentication.
- **Impacto potencial:** Contraseñas débiles (p. ej. `123456`) facilitan *credential stuffing* y fuerza bruta sobre cuentas que contienen PII (cédula, dirección, teléfono) e historias clínicas.
- **Evidencia:**
  ```dart
  // register_view_model.dart:125
  if (_password.isEmpty || _password.length < 6) return false;
  ```
- **Validación oficial:** Firebase Authentication soporta política de contraseñas configurable de **6 a 30 caracteres** más requisitos de mayúscula/minúscula/numérico/no-alfanumérico, y MFA por TOTP si se usa Identity Platform. NIST SP 800-63B-4 exige **mínimo 15 caracteres** para factor único (u 8 si hay MFA).
- **Remediación:**
  1. Activar la política de contraseñas en la consola (Authentication → Settings) — es autoritativa en servidor, no eludible.
  2. Subir el mínimo del cliente a **≥ 12** y mostrar medidor de fortaleza:
     ```dart
     bool get isPasswordValid {
       final p = _password;
       if (p.length < 12) return false;
       final hasUpper = p.contains(RegExp(r'[A-Z]'));
       final hasLower = p.contains(RegExp(r'[a-z]'));
       final hasDigit = p.contains(RegExp(r'[0-9]'));
       return hasUpper && hasLower && hasDigit;
     }
     ```
  3. Para cuentas de personal (ADMIN/SUPERADMIN), habilitar MFA TOTP.
- **Prioridad:** Media (alta para cuentas de personal).

---

### M-02 — La sesión sobrevive hasta 1 hora tras desactivar la cuenta en lecturas directas de Firestore/Storage (CWE-613)

- **Ubicación:** `firestore.rules` (funciones `isSignedIn`/`isActive`/`role`, líneas 7-17) y `storage.rules` (líneas 6-9); contrastar con `functions/src/domain/account.js:294` (`revokeRefreshTokens`) y `functions/src/auth/beforeUserSignedIn.js`.
- **Descripción:** Las reglas autorizan en función de `request.auth.token.status/role`, que son *claims* del **ID token**. Al desactivar una cuenta se llama a `revokeRefreshTokens` y `updateUser({disabled:true})`, pero el ID token ya emitido **sigue siendo válido hasta su expiración natural (~1 h)**. Durante esa ventana, el usuario desactivado conserva acceso de **lectura directa** a sus propios documentos (`users/{uid}`, sus `pets`, `appointments`, `proformas`, chat). Las *escrituras* de negocio no se ven afectadas porque van por callables que revalidan `status === 'ACTIVE'` dentro de transacción, y los nuevos inicios de sesión quedan bloqueados por `beforeUserSignedIn` + `disabled`.
- **Impacto potencial:** Un usuario recién dado de baja (voluntaria o administrativa) mantiene visibilidad de sus propios datos hasta ~1 h. No hay acceso a datos de terceros ni escritura. Impacto limitado y acotado a datos propios.
- **Evidencia:**
  ```
  // firestore.rules
  function isActive() { return isSignedIn() && request.auth.token.status == 'ACTIVE'; }
  ```
  El `status` proviene del token, no se reconsulta el documento en las reglas de lectura.
- **Validación oficial:** Documentación de Firebase (*Manage User Sessions*): *"existing ID tokens may remain active until their natural expiration (one hour)"*. La propia doc propone detectar la revocación en Security Rules guardando `tokensValidAfterTime` y comparando contra `auth_time`.
- **Remediación (si se quiere revocación inmediata en lecturas):**
  1. Persistir la marca de revocación en un documento legible por reglas, p. ej. `metadata/{uid}.revokedAt`, escrito por `executeAccountDeactivation`.
  2. Exigir en las reglas de lectura que el token sea posterior a esa marca:
     ```
     function notRevoked(uid) {
       return request.auth.token.auth_time * 1000 >
         get(/databases/$(database)/documents/metadata/$(uid)).data.revokedAtMillis;
     }
     allow read: if isOwner(userId) && notRevoked(userId);
     ```
  3. Alternativa de bajo coste: reducir el impacto documentando que la baja es efectiva de inmediato para escrituras y en ≤ 1 h para lecturas.
- **Prioridad:** Media.

---

## 🟢 Vulnerabilidades Bajas

### B-01 — La caché de idempotencia se devuelve sin verificar el propietario (CWE-639)

- **Ubicación:** `functions/src/callables/createAppointment.js:40-44`; `functions/src/callables/createProductRequest.js:52-58`; patrón análogo en `deliverProforma.js:62-66`.
- **Descripción:** Ante un `requestId` ya existente en `/idempotency/{requestId}`, la callable devuelve `idempotencyDoc.data().response` **sin comprobar que `response`/`userId` pertenezca al llamante**. El `requestId` lo genera el cliente con formato predecible `req_{uid}_{productId}_{timestamp}` (`product_detail_view_model.dart:122`, `catalog_view_model.dart:312`). Quien adivine un `requestId` ajeno recupera la respuesta cacheada (nombre de producto/mascota, precios, cantidades).
- **Impacto potencial:** Divulgación cruzada de detalles de una solicitud/cita ajena. Explotabilidad baja: requiere adivinar el UID, el productId y el milisegundo exacto.
- **Evidencia:**
  ```js
  const idempotencyDoc = await db.collection('idempotency').doc(requestId).get();
  if (idempotencyDoc.exists) {
    return idempotencyDoc.data()?.response;   // sin verificar propietario
  }
  ```
- **Remediación:** comprobar propiedad antes de devolver y/o derivar el requestId del servidor:
  ```js
  if (idempotencyDoc.exists) {
    if (idempotencyDoc.data()?.userId !== uid) {
      throw new HttpsError('permission-denied', 'Clave de idempotencia no válida.', { errorCode: 'IDEMPOTENCY_OWNER_MISMATCH' });
    }
    return idempotencyDoc.data().response;
  }
  ```
  (Nota: `createAppointment` no guarda `userId` en el doc de idempotencia; añadirlo al `set` de las líneas 331-336.)
- **Prioridad:** Baja.

### B-02 — `reactivateAccountOrPet` no registra auditoría ni valida el estado previo (CWE-778)

- **Ubicación:** `functions/src/callables/reactivateAccountOrPet.js` (ramas USER y PET, líneas 57-146).
- **Descripción:** Es la **única** callable de gobierno que no escribe en `/audit_log` (todas las demás —crear, desactivar, restablecer, moderar, bloquear agenda— sí lo hacen). Además no verifica que la entidad estuviera `DEACTIVATED` antes de ponerla `ACTIVE`. La reactivación de personal sí exige SUPERADMIN (bien), pero rompe la invariante de trazabilidad N-AD-08 del propio proyecto.
- **Impacto potencial:** Una acción privilegiada (reactivar cuentas/mascotas) queda sin rastro para el Super Usuario; dificulta investigación y no-repudio.
- **Remediación:** añadir `recordAuditLog(...)` con `action: 'REACTIVATE_ACCOUNT'`/`'REACTIVATE_PET'` y validar el estado origen:
  ```js
  if (userData.status !== USER_STATUS.DEACTIVATED) {
    throw new HttpsError('failed-precondition', 'La cuenta no está desactivada.', { errorCode: 'NOT_DEACTIVATED' });
  }
  // ...tras la mutación:
  await recordAuditLog(db, { actorUid: callerUid, actorName: request.auth.token?.name,
    actorRole: callerRole, action: 'REACTIVATE_ACCOUNT', targetType: 'USER', targetId: trimmedEntityId });
  ```
- **Prioridad:** Baja.

### B-03 — Sin límite de instancias/concurrencia: riesgo de DoS y factura inflada (CWE-770)

- **Ubicación:** todas las callables salvo `deliverProforma.js:21-22` (que sí fija `memory`/`timeoutSeconds`). No se usa `setGlobalOptions({ maxInstances })`.
- **Descripción:** Ninguna función limita `maxInstances`. Ante un pico (malicioso o no) Cloud Functions escala sin tope. App Check y reCAPTCHA mitigan el abuso automatizado, pero el *checklist* oficial de Firebase recomienda explícitamente limitar instancias para contener ataques de costo/DoS.
- **Impacto potencial:** Escalado ilimitado → degradación y coste elevado (el propio README advierte del coste de Cloud Run).
- **Remediación:** en `functions/src/index.js`:
  ```js
  import { setGlobalOptions } from 'firebase-functions/v2';
  setGlobalOptions({ maxInstances: 10, region: 'us-east1' });
  ```
  Ajustar el valor al tráfico esperado y, si procede, configurar alertas de presupuesto en Google Cloud.
- **Prioridad:** Baja.

### B-04 — Variables de plantilla de correo sin escape HTML (CWE-116)

- **Ubicación:** `functions/src/triggers/dispatch_mail.js:40-48` (`renderTemplate`, `return String(value)`), consumido en `:134` (`template.html`); plantillas en `scripts/seed.mjs:101,112`.
- **Descripción:** `renderTemplate` sustituye `{{clave}}` por `String(value)` **sin escapar HTML** e inserta el resultado en el cuerpo HTML del correo. Valores como `clientName` (de `users.fullName`) y `petName` (de `pets.name`) son controlados por el usuario y, aunque las reglas limitan su longitud, no restringen `<`, `>` ni comillas. Permite inyección de HTML/enlaces en el correo.
- **Impacto potencial:** Bajo. Los correos (`APPOINTMENT_CANCELLED`/`RESCHEDULED`) se envían **al propio cliente titular**, de modo que es auto-dirigido; los clientes de correo suelen neutralizar scripts. Aun así, inyección de enlaces/markup de *phishing* es posible y es mala práctica.
- **Remediación:** escapar en la sustitución del canal HTML:
  ```js
  const escapeHtml = (s) => String(s)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;').replace(/'/g,'&#39;');
  // en renderTemplate, para la variante HTML:
  return escapeHtml(value);
  ```
  (Mantener sin escape solo la variante `text`.)
- **Prioridad:** Baja.

### B-05 — reCAPTCHA Enterprise por *score* definido pero no aplicado en las mutaciones de negocio

- **Ubicación:** `functions/src/domain/guards.js:16` (`assertRecaptchaAssessment`, helper existente) vs. callables de negocio (`createAppointment`, `createProductRequest`, etc., que **no** lo invocan ni reciben `recaptchaToken`; ver payloads en `lib/data/services/functions_service.dart`). Solo `verifyHuman` usa `createAssessment` (clave de casilla).
- **Descripción:** Existe `assertRecaptchaAssessment(requestData, 'BOOK_APPOINTMENT', ...)` pero ninguna callable de mutación lo llama, y el cliente no envía `recaptchaToken`. La protección antibot de *score* queda efectivamente solo en el registro. Las mutaciones dependen de App Check + Auth + rol (que ya es una barrera sólida).
- **Impacto potencial:** Defensa en profundidad incompleta respecto al diseño (TRD menciona acciones `BOOK_APPOINTMENT`, `DELIVER_PROFORMA`). Bajo, porque App Check ya exige app legítima.
- **Remediación:** o bien cablear el *score* en las operaciones sensibles (enviar `recaptchaToken` desde el cliente con `RecaptchaService.executeAction('BOOK_APPOINTMENT')` y validar con `assertRecaptchaAssessment`), o bien eliminar el helper muerto para no inducir una falsa sensación de cobertura.
- **Prioridad:** Baja.

---

## ⚪ Hallazgos Informativos

### I-01 — `err.message` interno propagado al cliente (CWE-209)

`createAppointment.js:327` (`'Error al procesar la reserva de cita: ' + err.message`), `createUserAccount.js:193` (`originalMessage: error.message`), `setProformaAdjustments.js:78,82`, `addProformaItems.js`. Son errores de validación/infra de baja sensibilidad, pero conviene devolver un código genérico y registrar el detalle solo en logs del servidor.

### I-02 — CSP con `'unsafe-inline'` y `'wasm-unsafe-eval'` en `script-src`

`firebase.json:175`. Es un **requisito actual de Flutter Web** (bootstrap y CanvasKit/Skia-Wasm), no un descuido. Como endurecimiento futuro, Flutter admite CSP basada en *nonce*; documentarlo como deuda técnica. El resto de la CSP es ejemplar (`object-src 'none'`, `frame-ancestors 'none'`, `base-uri 'self'`).

### I-03 — `createAssessment` no verifica `tokenProperties.hostname`

`functions/src/lib/recaptcha.js`: se validan `valid`, `action` y `score`, pero no el `hostname`. La doc de reCAPTCHA Enterprise recomienda verificar el host cuando la clave no tiene verificación de dominio activada. Bajo, porque las claves web de Enterprise suelen estar ligadas a dominio. Añadir una comprobación opcional de `hostname` como refuerzo.

### I-04 — `completeRegistration` encadena escrituras sin transacción

`functions/src/callables/completeRegistration.js:87-135`: `users.set` → `setCustomUserClaims` → `chats.set` son `await` secuenciales. Un fallo intermedio deja estado parcial (auto-recuperable en siguiente intento). Riesgo de seguridad nulo; nota de robustez.

### I-05 — Datos de ejemplo con PII ficticia en el *showcase*

`lib/showcase/mock_data.dart` contiene correos `@example.com` y cédulas `0000000001`. Son datos de demostración claramente ficticios y `showcase_main.dart` es un entrypoint aparte. Verificar que el *showcase* **no** se despliega en el hosting de producción (el `build` por defecto compila `lib/main.dart`).

---

## 📋 Recomendaciones Generales

**Arquitectura de seguridad (ya sólida — mantener):**
- Conservar el *deny-by-default* y la regla de que toda escritura de negocio pase por callables transaccionales.
- Mantener la externalización de secretos; **nunca** versionar `config/app_config.json`, `functions/.env` ni cuentas de servicio.

**Mejoras recomendadas (por prioridad):**
1. Activar **política de contraseñas** en Firebase y **MFA/TOTP para personal** (M-01).
2. Decidir sobre la ventana de revocación de sesión de 1 h en lecturas (M-02).
3. Verificar propietario en la caché de idempotencia (B-01) y auditar la reactivación (B-02).
4. Fijar `maxInstances` y **alertas de presupuesto** en Google Cloud (B-03).
5. Escapar HTML en plantillas de correo (B-04).

**Buenas prácticas de despliegue (validar en consola, fuera del repo):**
- Confirmar que **App Check está en modo *enforce*** para Firestore, Storage, Authentication y Cloud Functions (el código lo exige; verificar que la consola no esté en "monitor").
- Restringir la **clave de API web por referente HTTP** y por API (son claves públicas por diseño, pero deben acotarse).
- Confirmar **protección contra enumeración de correo** activada (por defecto en proyectos creados desde 2023-09-15).
- Aplicar `storage-cors.json` sustituyendo `YOUR_PROJECT_ID` por los dominios reales (evitar orígenes comodín).

**Monitoreo y CI/CD:**
- Añadir a CI escaneo automático: `npm audit --audit-level=high`, `flutter pub outdated`, un escáner de secretos (p. ej. *gitleaks*/*detect-secrets*) como *pre-commit* y en *pull requests*, y pruebas de las reglas con el *Firebase Emulator Suite* (`@firebase/rules-unit-testing`).
- Activar *Dependabot*/*Renovate* y, si el plan lo permite, GitHub Advanced Security (*secret scanning* del repo no está disponible actualmente).
- Configurar alertas de Cloud Monitoring para picos de Firestore/Storage/Functions (detección de DoS).

---

## ✅ Checklist de Remediación

| ID | Vulnerabilidad | Severidad | Estado | Acción requerida |
|----|----------------|-----------|--------|------------------|
| M-01 | Política de contraseñas débil / sin MFA (CWE-521, CWE-308) | 🟡 Media | Abierto | Activar *password policy* en Firebase; subir mínimo cliente a ≥12 con complejidad; MFA TOTP para personal |
| M-02 | Sesión válida ≤1 h tras desactivar (lecturas) (CWE-613) | 🟡 Media | Abierto | Persistir `revokedAt` y comprobarlo en reglas de lectura, o documentar la ventana |
| B-01 | Caché de idempotencia sin verificar propietario (CWE-639) | 🟢 Baja | Abierto | Validar `userId === uid` antes de devolver `response`; guardar `userId` en `createAppointment` |
| B-02 | `reactivateAccountOrPet` sin auditoría ni validación de estado (CWE-778) | 🟢 Baja | Abierto | Añadir `recordAuditLog` y verificar estado `DEACTIVATED` previo |
| B-03 | Sin `maxInstances` / tope de coste (CWE-770) | 🟢 Baja | Abierto | `setGlobalOptions({ maxInstances })` + alertas de presupuesto |
| B-04 | Plantillas de correo sin escape HTML (CWE-116) | 🟢 Baja | Abierto | Escapar variables en la variante HTML de `renderTemplate` |
| B-05 | reCAPTCHA *score* definido pero no aplicado en mutaciones | 🟢 Baja | Abierto | Cablear `assertRecaptchaAssessment` en operaciones sensibles o retirar el helper |
| I-01 | `err.message` interno al cliente (CWE-209) | ⚪ Info | Abierto | Devolver código genérico; detalle solo en logs |
| I-02 | CSP con `'unsafe-inline'` (requisito de Flutter) | ⚪ Info | Aceptado | Deuda técnica: migrar a CSP con *nonce* cuando sea viable |
| I-03 | `createAssessment` no verifica `hostname` | ⚪ Info | Abierto | Verificar `tokenProperties.hostname` como refuerzo |
| I-04 | `completeRegistration` sin transacción | ⚪ Info | Abierto | Agrupar escrituras o tolerar reintento idempotente |
| I-05 | PII ficticia en *showcase* | ⚪ Info | Verificar | Confirmar que `showcase_main.dart` no se publica en producción |

---

### Referencias oficiales consultadas

- **Firebase — Manage User Sessions** (expiración de ID tokens ~1 h y revocación vía Security Rules): https://firebase.google.com/docs/auth/admin/manage-sessions
- **Firebase — API keys** (las claves web no son secretas; restringir por API/referente; el control de acceso real es Security Rules + App Check): https://firebase.google.com/docs/projects/api-keys
- **Firebase — Security checklist** (deny-by-default, App Check *enforce*, limitar instancias ante DoS): https://firebase.google.com/support/guides/security-checklist
- **Firebase — App Check en Cloud Functions** (`enforceAppCheck`, `consumeAppCheckToken`, tokens de uso limitado): https://firebase.google.com/docs/app-check/cloud-functions
- **Firebase — Blocking functions** (`beforeCreate`/`beforeSignIn`; auth anónima/custom no las dispara): https://firebase.google.com/docs/auth/extend-with-blocking-functions
- **Identity Platform — Password policy** (6–30 + complejidad): https://cloud.google.com/identity-platform/docs/password-policy
- **Identity Platform — Email enumeration protection** (por defecto desde 2023-09-15): https://cloud.google.com/identity-platform/docs/admin/email-enumeration-protection
- **reCAPTCHA Enterprise — Interpret assessments** (verificar `valid`, `action`, `hostname`, `score`): https://cloud.google.com/recaptcha/docs/interpret-assessment-website
- **Flutter — CSP y renderers Wasm/CanvasKit**: https://docs.flutter.dev/platform-integration/web/renderers
- **sharp — `limitInputPixels`** (protección anti *decompression bomb*, 268 MP por defecto): https://sharp.pixelplumbing.com/api-constructor/
- **OWASP Top 10:2025**: https://owasp.org/Top10/2025/
- **NIST SP 800-63B-4 — Passwords** (mínimo 15 / 8 con MFA): https://pages.nist.gov/800-63-4/sp800-63b.html
- **MITRE CWE**: CWE-521, CWE-308, CWE-613, CWE-639, CWE-770, CWE-116, CWE-209, CWE-778 — https://cwe.mitre.org/

> Auditoría realizada sobre código del que el solicitante declara ser propietario. No se ejecutaron exploits contra producción; las comprobaciones en vivo fueron pasivas (cabeceras, CORS y verificación de denegación de acceso anónimo). No se reprodujo ninguna credencial.
