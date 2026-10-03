// functions/src/config/runtime.js
// Opciones globales de despliegue aplicadas a TODAS las Cloud Functions.
//
// Debe evaluarse ANTES que cualquier módulo que defina funciones: setGlobalOptions sólo
// afecta a las funciones definidas después de su invocación. Por eso index.js importa este
// módulo en su primera línea, antes de los `export ... from './callables/...'` (el orden de
// evaluación de los módulos ES sigue el orden de aparición de los import/export).
//
// Las opciones por función (p. ej. `region`, o el `memory`/`timeoutSeconds` de deliverProforma)
// siguen teniendo prioridad; esto sólo fija valores por defecto para lo no especificado.

import { setGlobalOptions } from 'firebase-functions/v2';

// Tope de instancias concurrentes: red de seguridad frente a escalado abusivo (DoS / factura).
// App Check y reCAPTCHA ya filtran el abuso automatizado; este límite acota el coste.
// Ajustar al tráfico real del despliegue (Firebase Security Checklist).
setGlobalOptions({ maxInstances: 10 });
