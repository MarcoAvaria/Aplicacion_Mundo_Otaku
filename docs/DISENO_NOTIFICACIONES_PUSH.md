# Notificaciones push — diseño y costos

**Fecha:** 2026-09-24
**Estado:** propuesta. **No se ha tocado una sola línea de código.**
**Decide:** Marco Avaria.
**Decisión del 2026-09-24:** posponer el frente hasta cerrar lo que está
abierto. La modernización que lo condicionaba ya terminó, así que lo único que
falta es retomarlo cuando Marco lo diga.

> **Corrección del 2026-09-24, posterior a este documento.** El orden cambió:
> las notificaciones push van **después** de la modernización del cliente, no
> antes. Meter una dependencia nativa de Android justo antes de rehacer la cadena
> Gradle encarece esa migración sin ganar nada. Con eso, el "riesgo número uno"
> de la sección 3.2 —si `com.google.gms:google-services` convive con Gradle 7.5 y
> AGP 7.3.1— **se disuelve**, porque sobre la cadena nueva se usa la versión
> actual del plugin. El resto del documento sigue vigente. El plan está en
> [`PLAN_MODERNIZACION.md`](PLAN_MODERNIZACION.md).

Este documento existe para que puedas decidir si vale la pena, no para justificar
que se haga. Incluye la opción de no hacerlo y la recomienda por encima de la
versión completa en al menos un escenario.

Todo lo que aparece como "verificado" se comprobó ejecutando algo el 2026-09-24.
Lo que es suposición o estimación está marcado como tal.

---

## 1. De dónde partimos (verificado el 2026-09-24)

| Cosa | Estado |
| --- | --- |
| Cliente | `fe29fcf`, `main` y `mejora/calidad-portafolio` en el mismo commit, árbol limpio |
| API | `6ee65b4`, ídem (solo `postgres.roto-20260923/` sin versionar, basura conocida) |
| CI | Verde en ambos: Flutter `35952304067` y `35952301919`, Backend `35945791756` y `35942409774` |
| Flutter | 3.16.8, Dart 3.2.5 |
| Android | `applicationId` `com.marcoavaria.aplicacion_mundo_otaku`, `compileSdk` 34, AGP 7.3.1, Gradle 7.5 |
| Firebase en el código | **Ninguno.** Se retiró completo el 2026-09-13 en `06e0ae0` |

Y la pieza que hace que todo esto sea más barato de lo que parece:

**El servidor ya sabe a quién avisar.** `RealtimeNotifierService` mantiene una
sala de Socket.IO por persona (`user_<id>`), a la que el socket entra al
autenticarse ([`messages-ws.gateway.ts:49`](../../MundoOtaku-Backend-Repository/MundoOtaku-Backend-Repository/src/messages-ws/messages-ws.gateway.ts#L49)).
Hay **exactamente dos** lugares que ya resuelven el destinatario y llaman a
`notifyUsers`, los dos después de confirmar la transacción:

- [`chat-exchange.service.ts:204`](../../MundoOtaku-Backend-Repository/MundoOtaku-Backend-Repository/src/chat/chat-exchange.service.ts#L204) — cambió el estado de un intercambio.
- [`chat-exchange.service.ts:260`](../../MundoOtaku-Backend-Repository/MundoOtaku-Backend-Repository/src/chat/chat-exchange.service.ts#L260) — llegó un mensaje nuevo.

Cualquier diseño de push se cuelga de esos dos puntos y de ningún otro. Eso es lo
que evita tener que inventar de cero "quién debe enterarse de qué", que suele ser
la mitad del trabajo.

### Una corrección a la documentación existente

`ai-handoff/ROADMAP.md` (R-41) dice que se reutiliza el proyecto de Firebase
`mundo-otaku-crud` "ya configurado en 2023". **No se hereda tal cual.** El
`google-services.json` de 2023 sigue en el historial público del repositorio
(commit `6efc1a8`) y ahí se lee que la app Android estaba registrada como
`com.example.aplicacion_mundo_otaku`. Hoy el `applicationId` es
`com.marcoavaria.aplicacion_mundo_otaku`. Son identificadores distintos, así que
habría que registrar una app Android nueva de todas formas. Reutilizar el
proyecto viejo no ahorra el paso que se suponía que ahorraba.

**Decidido el 2026-09-24:** si se hace, se crea un proyecto de Firebase nuevo y
limpio, sin Auth ni Firestore habilitados.

### Alcance de plataformas

**Decidido el 2026-09-24: solo Android**, sobre tu Galaxy SM-S938B.

- **iOS queda fuera** porque el push real exige una cuenta del Apple Developer
  Program (paga) y un Mac para firmar. Con planes gratuitos no hay forma de
  verificarlo, y una función que no se puede probar no se declara hecha.
- **Flutter Web queda fuera** por decisión tuya. Vale la pena que quede escrito
  lo que eso implica, porque no es menor: la demo pública
  (`mundo-otaku-web.onrender.com`) es precisamente Flutter Web, así que **quien
  revise tu portafolio no verá esta función funcionando**. Vive solo en el APK
  instalado en tu teléfono. Esto pesa en la recomendación final.

---

## 2. Qué avisos tienen sentido y cuáles no

### Sí

| Aviso | A quién | Por qué |
| --- | --- | --- |
| Te llegó un mensaje en un intercambio en curso | Al que **no** escribió | Es el caso real. Hoy, con la app cerrada, no te enteras nunca. |
| Te propusieron un intercambio | Al dueño del producto pedido | Hoy la propuesta queda esperando en una bandeja que nadie mira. Es el aviso con más valor después del mensaje. |
| Aceptaron tu propuesta | Al que propuso | Abre el chat. Es el momento en que la app pasa a ser útil. |
| Rechazaron o cancelaron tu propuesta | Al otro lado | Cierra el ciclo. Menos urgente, pero deja la bandeja consistente. |

Son cuatro, y los cuatro salen de los dos puntos que ya existen. No hay que
inventar ningún evento nuevo en el servidor.

### No

| Aviso | Por qué no |
| --- | --- |
| "Alguien vio tu producto" | Ruido. No hay nada que hacer al respecto. |
| "Hay productos nuevos en el catálogo" | Es publicidad, no un aviso. Con 8 productos demo, además, es absurdo. |
| Resúmenes diarios o recordatorios | Exigen un trabajo programado (cron) que hoy no existe, y en Render free no hay forma gratuita razonable de correrlo. Costo alto, valor cero. |
| Avisar a quien hizo la acción | Ya lo sabe: acaba de hacerlo. |
| Reenviar un aviso si no lo abres | Es una función de producto completa (reintentos, silencio, horarios) disfrazada de detalle. |

### Y la regla que hace que esto no moleste

**Push solo si la persona no está conectada.** Antes de mandar, el servidor
puede preguntar si la sala `user_<id>` tiene algún socket vivo
(`server.in(room).fetchSockets()`). Si lo tiene, esa persona ya se enteró por
tiempo real y un push sería un aviso doble; si no lo tiene, va el push.

Esto es barato precisamente porque la sala ya existe. Es el argumento más fuerte
a favor de que este frente cueste menos de lo que parece.

**La trampa, dicha ahora y no después:** con la app en segundo plano el socket
sobrevive un rato y después Android lo mata. Durante esa ventana el servidor cree
que estás conectado y no manda push, pero tú no estás mirando la pantalla. El
resultado es un aviso que no llega. No tiene arreglo limpio sin inventar latidos
y estados de "activo de verdad", que es más complejidad de la que este proyecto
justifica. La forma barata de vivir con eso es que el cliente desconecte el
socket a propósito cuando la app pasa a segundo plano, y lo reconecte al volver.
Entonces "conectado" pasa a significar "mirando la pantalla", que es lo que
queremos que signifique.

### El contenido del mensaje: una decisión tuya

Hoy el servidor manda por la sala personal **solo el identificador del
intercambio, nunca el texto**, y está comentado a propósito en el código. Para
push hay dos caminos:

- **Sin contenido** — "Usuario Demo 2 te escribió". El texto del mensaje no sale
  nunca de tu infraestructura ni queda en la bandeja de notificaciones del
  teléfono. Mantiene la propiedad que el servidor ya cuida.
- **Con contenido** — "Usuario Demo 2: ¿te sirve el tomo 3?". Es lo que hace
  WhatsApp y es claramente más útil. El costo es que el texto pasa por los
  servidores de Google y queda visible en la pantalla bloqueada.

Recomiendo **sin contenido**, por coherencia con lo que el servidor ya decidió y
porque con datos demo la utilidad extra es nula. Pero es tu decisión y no cambia
la arquitectura: es un campo más o un campo menos en el mismo envío.

---

## 3. Qué exige Firebase Cloud Messaging

### 3.1 En el proyecto de Firebase

Todo esto es gratuito, en el plan Spark, sin tarjeta:

1. Crear un proyecto nuevo (sin Analytics, para no arrastrar consentimientos).
2. Registrar una app **Android** con `com.marcoavaria.aplicacion_mundo_otaku`.
3. Descargar `google-services.json`.
4. Habilitar la **Cloud Messaging API (V1)**. La API heredada está retirada, así
   que no hay atajo por ahí.
5. Generar una **clave de cuenta de servicio** (Configuración → Cuentas de
   servicio → Generar nueva clave privada). Es un JSON.
6. **No habilitar** Authentication ni Firestore. El alcance es mensajería y nada
   más, igual que la decisión de 2026-09-15.

### 3.2 En el cliente Flutter

**Verificado el 2026-09-24** con `flutter pub add --dry-run` (no modificó nada;
el árbol quedó limpio): las versiones que resuelven en Flutter 3.16.8 son

```
firebase_core       2.27.0     (la actual es 4.15.0)
firebase_messaging  14.7.19    (la actual es 16.7.0)
```

Es decir, **dos años de atraso desde el primer día**. Entra y compila, pero
nace viejo, y eso importa por lo que está escrito en la sección 6.

Lo que hay que agregar:

- Las dos dependencias, fijadas a esas versiones.
- `android/app/google-services.json`, **ignorado por git**.
- El plugin de Gradle: `classpath 'com.google.gms:google-services:4.3.15'` en
  `android/build.gradle` y `apply plugin: 'com.google.gms.google-services'` en
  `android/app/build.gradle`. *Suposición por verificar:* la 4.3.15 es la última
  rama compatible con Gradle 7.5 / AGP 7.3.1; las 4.4.x piden una cadena más
  nueva. Hay que comprobarlo compilando, y `PRECAUCIONES.md` prohíbe subir
  Gradle/AGP como efecto secundario de otra tarea. **Si resulta incompatible,
  este frente se bloquea detrás de la migración de Android 17.** Es el riesgo
  técnico número uno del diseño.
- Permiso `POST_NOTIFICATIONS` en el manifiesto **y pedido en tiempo de
  ejecución**. Desde Android 13 no se concede solo, y tu teléfono es Android 16.
  Si se olvida, todo "funciona" y no llega nada.
- Un canal de notificación de importancia alta. Sin canal, Android no muestra
  nada en primer plano.
- Un manejador de segundo plano como función de nivel superior anotada con
  `@pragma('vm:entry-point')`. Es un requisito del plugin, no un detalle de
  estilo.
- Registrar el token después de iniciar sesión, renovarlo con `onTokenRefresh`,
  y **borrarlo al cerrar sesión**. Esto último no es opcional: sin eso, los
  avisos de una cuenta siguen llegando al teléfono después de salir de ella.
- Al tocar la notificación, abrir el intercambio correspondiente con GoRouter.

### 3.3 En la API NestJS

- Dependencia nueva `firebase-admin`. Es pesada; ver el riesgo de memoria en la
  sección 5.
- Una tabla nueva `device_tokens` (`user_id`, `token`, `platform`, `updated_at`),
  con el token como clave y una restricción única. **Migración nueva**, sin tocar
  las cinco existentes.
- Dos rutas: registrar el token y darlo de baja al cerrar sesión.
- Un `PushNotifierService`, hermano de `RealtimeNotifierService` y con la misma
  forma: no falla si no está configurado, y un envío perdido nunca tumba la
  operación que lo provocó. Se llama desde los mismos dos puntos del
  `ChatExchangeService`, después de la transacción.
- **Limpieza de tokens muertos.** Cuando FCM responde
  `messaging/registration-token-not-registered`, esa fila se borra. Si no se
  hace, la tabla se llena de tokens de instalaciones que ya no existen y cada
  envío se va haciendo más lento. Es el detalle que casi siempre se omite.
- La API debe seguir arrancando y pasando CI **sin** credencial de Firebase
  configurada, con el push simplemente apagado. Si no, rompes el entorno local y
  el de pruebas de todo el mundo por una función opcional.

### Cómo se prueba

- **Automatizable:** la lógica de "a quién le toca" y "está conectado o no"
  se prueba con el envío real reemplazado por un doble. Eso cubre lo que
  realmente puede romperse.
- **No automatizable:** que la notificación aparezca en la pantalla. Eso se
  verifica a mano, en tu teléfono, con la app cerrada, cada vez. Ni CI ni
  Playwright pueden hacerlo.

Este es el primer trozo del proyecto que no se puede verificar de extremo a
extremo de forma automática. Conviene saberlo antes de empezar, no después.

---

## 4. Credenciales: cuáles son y cómo no terminan en el repositorio

Hay dos archivos y **solo uno es realmente un secreto**. Confundirlos lleva a
proteger el equivocado.

| Archivo | Qué es | ¿Secreto? | Dónde vive |
| --- | --- | --- | --- |
| `google-services.json` | Configuración del cliente: identificador del proyecto y clave de API de Android | **No de verdad.** Va dentro del APK; cualquiera con el APK lo extrae en un minuto | `android/app/`, ignorado por git igual, por higiene |
| Clave de cuenta de servicio (`.json` con `private_key`) | Credencial de **administrador del proyecto de Firebase** | **Sí, absolutamente** | Solo en el panel de Render y en un `.env` local ignorado |

Sobre el de 2023 que está en el historial público: es el primero, el que no es
secreto. No es una filtración que haya que remediar. Lo que sí habría sido grave
es que estuviera ahí una clave de cuenta de servicio, y no lo está.

**Medidas concretas:**

- Agregar a `.gitignore` del cliente: `**/google-services.json`.
- Agregar a `.gitignore` de la API: `**/firebase-service-account*.json`.
- En Render, la clave va como variable de entorno (el JSON completo en una
  línea, o en base64), nunca como archivo.
- **Nunca cargar ese archivo con `source` en bash.** Ya pasó el 2026-09-15 con
  `.env.neon`: un BOM invisible hizo que `source` intentara ejecutar la línea
  como comando y **imprimiera la cadena de conexión completa con contraseña** en
  la salida. Hubo que rotar la contraseña de Neon. Las formas seguras están en
  `ai-handoff/PRECAUCIONES.md`.
- El `.env` del cliente se empaqueta dentro de la app, así que sigue valiendo la
  regla: ahí solo configuración pública. Nada de Firebase necesita ir ahí.

---

## 5. La demo pública y las cuentas de prueba

Aquí están los problemas honestos, no los tranquilizadores.

**La demo pública no tendrá push.** Es Flutter Web, y Web quedó fuera del
alcance. La función existirá únicamente en el APK de tu teléfono. Como pieza de
portafolio, eso significa que hay que *contarla* en vez de *mostrarla*, salvo que
grabes un video con el teléfono. Es el argumento en contra más fuerte de todo el
documento.

**Las cuentas demo son compartidas y públicas.** Sus credenciales están en los
README de ambos repositorios. Si instalas el APK, inicias sesión como Usuario
Demo 1 y dejas la sesión abierta, **recibirás notificaciones cada vez que un
desconocido use esa cuenta en la demo web**. No es una falla de seguridad —el
aviso no lleva nada privado, y menos aún si va sin contenido— pero es molesto y
es fácil no anticiparlo. La forma de vivir con ello es cerrar sesión en el
teléfono cuando no estés probando, porque el cierre de sesión da de baja el
token.

**Render free duerme a los 15 minutos.** En la práctica no estorba: un push nace
de una escritura en la API, así que si la API duerme es porque nadie escribió y
no hay nada que notificar. El único efecto es que el primer mensaje después de
dormir tarda cerca de un minuto, y el push sale detrás.

**Neon free:** la tabla de tokens es de unas pocas filas. No se acerca al tope de
0,5 GB compartido con los datos y las fotos.

**El riesgo que sí hay que medir: la memoria.** Render free da 512 MB y las 750
horas mensuales son **por workspace y compartidas**. `firebase-admin` es una
dependencia pesada y agrega memoria al proceso de la API. Si se pasa del límite,
Render reinicia el servicio. La API de Mundo Otaku está en el workspace
"Workspace-Mundo-Otaku", separada de `App-Gym-Backend`, así que **no puede tumbar
la app de Gym**; eso ya está bien aislado. Pero sí puede volver inestable la demo
de Mundo Otaku, y eso hay que medirlo con la imagen de producción en local antes
de desplegar nada, no descubrirlo en la nube.

---

## 6. Qué cuesta mantenerlo

**En dinero: cero.** FCM es gratuito y sin tope de mensajes, y lo seguirá siendo
para este volumen. Esa parte de la decisión de 2026-09-15 es correcta.

**El costo es de otra naturaleza**, y es el que conviene mirar:

- **Una dependencia nativa de Android más.** Desde que entre, cada actualización
  de Flutter, de Gradle o de AGP tiene que pasar también por Firebase. Tienes
  pendiente la migración a Android 17, así que esto se cruza con un frente que ya
  existe.
- **Nace con dos años de atraso** (14.7.19 frente a 16.7.0). Cuando actualices
  Flutter, este salto de versiones será parte del trabajo, y los saltos grandes
  de FlutterFire históricamente traen cambios que rompen.
- **Deja de haber verificación automática de extremo a extremo.** Todo lo demás
  del proyecto lo comprueba CI o Playwright. Esto no. Cada cambio que roce el
  chat o la sesión exige volver a probar a mano con el teléfono.
- **Google retira APIs.** La API heredada de FCM murió en 2024. Esto no es un
  "instalar y olvidar" a diez años.
- **Una credencial crítica más que custodiar y rotar.**
- **Esfuerzo de construcción, estimado y no medido:** el trabajo de servidor es
  modesto, porque los dos puntos de aviso ya existen; el de cliente es mediano,
  por los permisos, el canal y el ciclo de vida del token; y el mayor riesgo de
  que se alargue está en la cadena de Gradle, que puede convertir esto en la
  migración de Android 17 disfrazada.

---

## 7. Alternativas más baratas

### A. No hacerlo

**Costo: cero.**

Ya tienes tiempo real dentro de la app (T-036) y el contador de no leídos
(T-035). Con la app abierta te enteras de todo al instante. Lo único que falta
es el aviso con la app cerrada, que es exactamente lo que **no se puede mostrar
en la demo web** de todos modos.

Es una opción seria, no un relleno. En una demostración en vivo de portafolio,
nadie nota su ausencia.

### B. Notificaciones locales, sin Firebase y sin servidor

**Costo: bajo.** Una dependencia (`flutter_local_notifications`), cero
credenciales, cero migraciones, cero cambios en la API, cero servicios externos.

El socket ya está conectado y ya recibe `exchange-activity`. Cuando llegue ese
aviso con la app en segundo plano, la app pinta una notificación del sistema
ella misma.

**La limitación, sin maquillar:** Android mata el socket a los pocos minutos de
segundo plano, y con la app **cerrada** no hay socket ni notificación. Así que
esto cubre la ventana corta de segundo plano y nada más. Es la mitad del valor.

**Pero hay un detalle que cambia el cálculo:** B no es un desvío respecto de
FCM, es un **subconjunto**. El permiso `POST_NOTIFICATIONS`, el canal de
notificación Android, el pintado del aviso y la navegación al tocarlo son el
mismo código en ambos caminos. Si después haces FCM, nada de B se tira: lo único
que cambia es de dónde viene el disparo. Hacer B primero no es gastar dos veces.

### C. Quedarse con lo que hay, mejorando el sello de no leídos

**Costo: casi cero.** Ya existe y funciona entre dispositivos desde que la marca
de lectura vive en el servidor. Se podría extender a la bandeja de propuestas
recibidas, que hoy no tiene contador.

### D. FCM completo

Lo descrito en las secciones 2 a 6.

### Descartadas, y por qué

| Opción | Por qué no |
| --- | --- |
| OneSignal, Pusher Beams, AWS SNS | Son capas **encima** de FCM. Sigues haciendo el mismo trabajo en el cliente Android, y encima agregas otro proveedor, otra cuenta y otro límite gratuito. No evitan nada. |
| `ntfy` (autohospedado o público) | Gratis y sin Google, pero exige que quien recibe instale la app de ntfy, o empaquetar su cliente. Pierde justo lo que da valor de portafolio: que sea el mecanismo que usa la industria. |
| Web Push / VAPID sin Firebase | Es una alternativa real y gratuita, pero es **Web**, y Web quedó fuera del alcance. Si algún día la demo pública tuviera que mostrar la función, este es el camino a reabrir. |
| Correo electrónico en vez de push | Necesita un proveedor de envío y direcciones reales; las cuentas demo son ficticias. |

---

## 8. Recomendación

**Hacer B ahora y decidir D después, con B ya funcionando en tu teléfono.**

Las razones, en orden de peso:

1. B se puede verificar esta misma semana en tu Galaxy, sin crear una sola cuenta
   externa, sin una credencial nueva y sin tocar la cadena de Gradle, que es el
   riesgo que puede convertir D en la migración de Android 17.
2. B no se pierde si después haces D: es su subconjunto, no un atajo distinto.
3. Con B funcionando vas a saber, mirando tu propio teléfono, cuánto te importa
   de verdad el caso "app completamente cerrada". Hoy eso es una suposición; en
   una semana sería un dato.
4. D no se ve en la demo pública, así que su valor de portafolio depende de que
   lo cuentes o lo grabes, no de que alguien lo pruebe.

Si lo que quieres es específicamente la línea "integré Firebase Cloud Messaging"
en el currículum, entonces D es el camino y esa es una razón legítima. Pero
entonces conviene decirlo así, porque cambia el orden de todo lo demás.

**Lo que recomiendo no hacer en ningún escenario:** empezar por D sin haber
comprobado antes, en una rama desechable, que `com.google.gms:google-services`
compila con Gradle 7.5 y AGP 7.3.1. Esa comprobación cuesta poco y decide si el
frente está abierto o bloqueado.

---

## 9. Lo que necesito que decidas

1. **¿A, B, C o D?** Mi recomendación es B ahora, D como decisión aparte después.
2. **Si vas a D: ¿el push lleva el texto del mensaje o no?** Recomiendo que no.
3. **Si vas a D: ¿qué hace CI?** El job de Flutter compila un APK, y con el
   plugin de Firebase aplicado el build falla sin `google-services.json`. Las dos
   salidas son guardar ese archivo como secreto de GitHub Actions, o dejar el
   plugin condicionado a que el archivo exista. Prefiero la segunda: mantiene el
   repositorio clonable y compilable por cualquiera, sin secretos.

Mientras no respondas, no se toca código. Este documento es lo único que existe.

---

## 10. Fuera del alcance, sin discusión

Ya estaban descartados y aquí no se reabren: Firebase Authentication, Firestore,
login social, editar mensajes, enviar imágenes en el chat, borrar mensajes, el
indicador "Escribiendo…" y el acuse de "visto".

Aclaración sobre el último, porque se presta a confusión: el proyecto **sí**
tiene marcas de lectura (`chat_exchange_reads` y `PATCH /chat-exchanges/:id/read`),
pero sirven para tu propio contador de no leídos, no para mostrarle a la otra
persona que leíste su mensaje. Eso segundo es lo descartado, y sigue descartado.
