# Política de seguridad

## Cómo reportar una vulnerabilidad

**No abras un *issue* público.** Usa el reporte privado de GitHub: pestaña **Security → Report a vulnerability** de este repositorio. Incluye los pasos para reproducirla, el impacto y, si puedes, una propuesta de corrección.

## Qué no debe subirse nunca a este repositorio

- Archivos `.env`, `config/app_config.json`, `.firebaserc` (están en `.gitignore`).
- Cuentas de servicio (`*serviceAccount*.json`, `*-adminsdk-*.json`), claves privadas, contraseñas o claves SMTP.
- **Tokens de depuración de App Check**: quien los tenga puede saltarse App Check.
- Exportaciones de usuarios de Firebase Auth (contienen hashes de contraseñas).

Si algo de esto se subió por error, **rótalo de inmediato**: borrar el archivo o el commit no basta, porque queda en el historial y en las copias.

## Qué es público por diseño

La clave de API del cliente web de Firebase, el `appId`, el `projectId` y las claves de sitio de reCAPTCHA se incluyen en el código compilado de cualquier app web. No son secretos, pero deben protegerse así:

- Restringe la clave de API por **referente HTTP** y por **API** en Google Cloud.
- Activa **App Check** y haz que las reglas de Firestore y Storage y las Cloud Functions lo exijan.
- Mantén las reglas de seguridad en modo denegar por defecto.

## Responsabilidad de quien despliega

Cada despliegue es responsabilidad de quien lo realiza: configurar sus propios secretos en Secret Manager, restringir sus claves, revisar los costes de Google Cloud y mantener actualizadas las dependencias (`npm audit`, `flutter pub outdated`).
