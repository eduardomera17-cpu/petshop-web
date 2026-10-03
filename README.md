# PetShop — gestión de citas, atención clínica y venta en mostrador

Aplicación web privada para un petshop con dos experiencias: **cliente** (mascotas, citas, catálogo y solicitudes de producto, carrito, proformas, chat con el personal) y **panel de administración** (agenda, atención clínica, inventario, productos y servicios, proformas, gobierno de cuentas y parámetros del negocio). Se desarrolló como proyecto de tesis de tecnología en desarrollo de software.

Está construida únicamente con **Flutter / Dart**, **Firebase** y **Google Cloud**:

| Capa | Tecnología |
| --- | --- |
| Cliente web | Flutter Web (Dart), `provider`, `go_router`, `freezed` / `json_serializable` |
| Identidad | Firebase Authentication (con funciones de bloqueo `beforeUserCreated` / `beforeUserSignedIn`) |
| Datos | Cloud Firestore (base con nombre `petshopdev`) con reglas de seguridad en `firestore.rules` |
| Archivos | Cloud Storage con reglas en `storage.rules` |
| Lógica de servidor | Cloud Functions for Firebase 2.ª generación (Node.js 24) en `functions/` |
| Protección | Firebase App Check + reCAPTCHA Enterprise |
| Alojamiento | Firebase Hosting (cabeceras de seguridad y CSP en `firebase.json`) |

## Estructura

```
lib/            Aplicación Flutter (app, core, data, domain, ui, l10n, showcase)
functions/      Cloud Functions (src/auth, callables, triggers, domain, lib, config)
scripts/        Siembra de datos iniciales y aprovisionamiento del Super Usuario
web/            Plantilla HTML y manifiesto PWA
config/         Plantilla de configuración del cliente (app_config.example.json)
firestore.rules · firestore.indexes.json · storage.rules · storage-cors.json · storage-lifecycle.json · firebase.json
```

## Requisitos

- Flutter con Dart `>=3.12 <4.0`
- Node.js `>=24` y npm
- Firebase CLI (`npm i -g firebase-tools`)
- Un proyecto de Firebase propio (las Cloud Functions de 2.ª generación exigen el plan Blaze)

## Configuración

**Este repositorio no contiene ninguna clave, identificador de proyecto ni credencial.** Cada despliegue aporta la suya. Todo lo que sigue se configura con archivos que **no se versionan** (están en `.gitignore`).

### 1. Proyecto de Firebase

1. Crea el proyecto y registra una app web.
2. Activa **Authentication** (correo y contraseña). Las funciones de bloqueo de Auth requieren actualizar a Identity Platform.
3. Crea la base de **Firestore** con el nombre `petshopdev` y en **edición Enterprise**, que es lo que declara `firebase.json` (también para el emulador). Si prefieres otro nombre o edición, cámbialo en `firebase.json`, `lib/data/services/firestore_service.dart` y `functions/src/config/constants.js`.
4. Activa **Cloud Storage** y **App Check**.
5. En **reCAPTCHA Enterprise** crea dos claves web: una de *puntuación* (invisible) y una de *casilla* (visible).
6. Enlaza la CLI con tu proyecto:

```bash
cp .firebaserc.example .firebaserc      # y pon el id de tu proyecto
# o bien: firebase use --add
```

### 2. Cliente Flutter

```bash
cp config/app_config.example.json config/app_config.json   # rellénalo con los valores de tu app web
```

Los valores van **dentro del JavaScript compilado**, así que no son secretos: son las claves públicas del cliente web y las claves de sitio de reCAPTCHA. La protección real está en restringir la clave de API por referente HTTP, en App Check y en las reglas de seguridad.

Esa es **la única fuente de configuración del cliente**: la aplicación carga el SDK de reCAPTCHA Enterprise con `RECAPTCHA_SCORE_SITE_KEY` al arrancar, así que **no hay que editar `web/index.html`** ni ningún otro archivo versionado.

### 3. Cloud Functions

```bash
cd functions
npm ci
cp .env.example .env            # rellénalo: bucket, claves de sitio, remitente y servidor SMTP
firebase functions:secrets:set BREVO_SMTP_KEY    # clave SMTP: SOLO en Secret Manager, nunca en el código
```

`functions/.env` lo lee la Firebase CLI (despliegue y emuladores), **no** `node`. Si ejecutas un script suelto con `node`, pasa las variables en la propia línea de órdenes (por ejemplo `STORAGE_BUCKET=… node scripts/…`); los scripts de siembra no necesitan bucket.

**Versiones de las dependencias.** `package-lock.json` fija `firebase-admin` 14 y Node 24, con 0 vulnerabilidades conocidas (`npm audit --omit=dev`). El código se desarrolló y se ejecutó en producción con `firebase-admin` 13: la 14 se ha comprobado ejecutando la siembra y el aprovisionamiento del Super Usuario contra los emuladores de Auth y Firestore, pero las callables no se han probado de extremo a extremo con ella.

### 4. Storage

Edita `storage-cors.json` (sustituye `YOUR_PROJECT_ID`) y aplica CORS y caducidad de subidas:

```bash
gcloud storage buckets update gs://TU_BUCKET --cors-file=storage-cors.json --lifecycle-file=storage-lifecycle.json
```

## Ejecutar y compilar

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=config/app_config.json
flutter build web --release --dart-define-from-file=config/app_config.json
```

Si falta algún valor obligatorio, la aplicación **no arranca y la página queda en blanco**; el mensaje, que lista las claves ausentes, aparece en la **consola del navegador (F12)**.

El cliente se conecta al proyecto configurado; **no incluye conmutación automática a los emuladores**. Reglas y funciones sí se pueden probar con el Emulator Suite (`firebase emulators:start`: Auth 9099, Firestore 8080, Storage 9199, Functions 5001).

`lib/showcase_main.dart` es un punto de entrada alternativo con repositorios simulados y **datos ficticios**, pensado para capturas de pantalla (`flutter run -d chrome -t lib/showcase_main.dart`).

### Datos iniciales y Super Usuario

Con los emuladores en marcha (`firebase emulators:start`), desde la raíz del repositorio:

```bash
cd functions && npm ci && cd ..
export GCLOUD_PROJECT=demo-petshop FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
node scripts/seed.mjs
SUPERADMIN_EMAIL=tu@correo.example node scripts/provision-superadmin.mjs --confirm
```

Contra un proyecto real (bajo tu responsabilidad) no definas las variables de emulador, usa credenciales de aplicación de Google y pasa también `SUPERADMIN_PASSWORD`.

El Super Usuario **no tiene correo ni contraseña por omisión**: ambos se indican por variables de entorno. Solo si Auth *y* Firestore apuntan a emuladores se genera una clave aleatoria efímera.

## Despliegue

```bash
flutter build web --release --dart-define-from-file=config/app_config.json
firebase deploy --only hosting,firestore,storage
```

Desplegar las Cloud Functions (`firebase deploy --only functions`) ejecuta servicios de Cloud Run en tu proyecto y **genera costes**; revisa la facturación antes de hacerlo.

## Seguridad

Consulta [SECURITY.md](SECURITY.md). Resumen: no subas `.env`, `config/app_config.json`, cuentas de servicio ni tokens de depuración de App Check; restringe tus claves de API; y reporta las vulnerabilidades de forma privada.

## Licencia

Este programa es software libre: puedes redistribuirlo y/o modificarlo bajo los términos de la **GNU General Public License** publicada por la Free Software Foundation, ya sea la versión 3 de la Licencia o (a tu elección) cualquier versión posterior.

Se distribuye con la esperanza de que sea útil, pero **SIN NINGUNA GARANTÍA**, ni siquiera la garantía implícita de COMERCIABILIDAD o IDONEIDAD PARA UN PROPÓSITO PARTICULAR. Consulta el archivo [LICENSE](LICENSE) para más detalles.
