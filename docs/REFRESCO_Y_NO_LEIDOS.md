# Refresco de intercambios y contador de mensajes no leídos (T-035)

**Estado:** implementado y verificado con pruebas automáticas y en teléfono real, sin commit · **Fecha:** 2026-09-20, verificado en dispositivo el 2026-09-21 · **Rama:** `mejora/calidad-portafolio` (cliente Flutter)

Este documento explica por qué y cómo se agregaron el refresco manual, la
actualización automática tras cambiar el estado de un intercambio y el contador
de mensajes no leídos. Al final hay una **bitácora** que se va completando paso a
paso, para poder retomar el trabajo en otra sesión sin releer el código.

## Qué se pidió

1. Refresco de tipo *pull-to-refresh* en las bandejas **Enviadas** y **Recibidas**,
   que vuelva a pedir los datos a la API.
2. Que al **cancelar** una solicitud enviada, o al **rechazar** una recibida, la
   bandeja se actualice sola, sin tener que salir y volver a entrar.
3. Refresco en los chats de intercambio, y un contador de mensajes no leídos como
   un círculo pequeño sobre cada tarjeta de "Intercambio en curso". Cuando el
   número es 0, el círculo debe ser gris opaco con línea punteada: perceptible,
   pero casi mimetizado con el fondo.

## Decisiones tomadas antes de implementar

Las tres las eligió Marco el 2026-09-20, después de revisar las alternativas.

### Alcance del "listener": solo cliente

No se toca la API. La actualización automática cubre todo lo que hace la persona
usuaria en su propio dispositivo y se apoya en cuatro disparadores:

- el gesto manual de *pull-to-refresh*;
- el cambio de estado de un intercambio (cancelar, rechazar, aceptar, completar);
- volver a una lista desde una pantalla hija;
- reanudar la aplicación desde segundo plano.

**Limitación conocida y aceptada:** si la otra persona escribe o responde mientras
la pantalla está abierta y quieta, no se ve hasta refrescar. El tiempo real
verdadero exigiría una sala de Socket.IO por usuario en NestJS, porque hoy el
*gateway* (`src/messages-ws/messages-ws.gateway.ts`) emite `new-message`
únicamente a la sala de la conversación que el cliente tiene abierta, y el
`SocketService` del cliente solo se une a una conversación a la vez. Queda anotado
como mejora futura, no se implementó.

### Base del contador: marca local por dispositivo

Se guarda la fecha del último mensaje visto en cada intercambio con
`flutter_secure_storage`, siguiendo el mismo patrón inyectable de
`AppThemeModeNotifier`. No requiere migración ni endpoints nuevos. A cambio, los
contadores parten de cero al reinstalar la aplicación o al entrar desde otro
dispositivo, lo que para una demostración de portafolio es aceptable.

La alternativa descartada era un campo de "último mensaje leído" por participante
en la API, con migración, endpoint y pruebas nuevas del backend.

### Refresco del chat: en la lista y dentro de la conversación

En la pantalla de Chats el gesto recarga intercambios y productos desde la API.
Dentro de una conversación abierta vuelve a pedir el historial por el socket, que
es útil cuando la conexión se cortó y se recuperó.

## Habilitador: la API ya mandaba lo necesario

`GET /api/chat-exchanges/user/:id` devuelve cada intercambio con su columna
`messages` (`jsonb`), y cada mensaje trae `content`, `timestamp` y `sendBy`. El
mapper del cliente descartaba los dos últimos y dejaba solo el texto, así que el
contador de no leídos se puede calcular **sin ningún cambio en el backend**: basta
con dejar de botar esa información.

## Bitácora

Cada paso se anota al terminarlo, con lo que se verificó.

### Paso 1 — el dominio conserva autor y fecha de cada mensaje

`ChatExchange.messages` pasó de `List<String>` a `List<ChatExchangeMessage>`, una
entidad nueva en `lib/features/chats/domain/entities/chat_exchange_message.dart`
con `content`, `sendBy` y `timestamp`. `sendBy` queda vacío y `timestamp` nulo en
los mensajes antiguos que no traen esos campos, y el mapper tolera además que la
clave `messages` no venga o no sea una lista.

- Archivos: `chat_exchange_message.dart` (nuevo), `chat_exchange.dart`,
  `chat_exchange_mapper.dart`, `test/features/chats/chat_exchange_mapper_test.dart`.
- Verificado: la prueba falló primero por los campos inexistentes; después
  `flutter test test/features/chats/` → 8 de 8.

### Paso 2 — marcas de lectura locales

`lib/features/chats/presentation/providers/chat_read_marks_provider.dart` guarda
un mapa `{id de intercambio: fecha del último mensaje visto}` como un único JSON
en `flutter_secure_storage`, con `loadMarks`/`saveMarks` inyectables.

Detalles que vale la pena recordar:

- La marca se mueve con la **fecha del mensaje**, no con la hora del dispositivo,
  para que un reloj desajustado no deje mensajes eternamente sin leer.
- La marca nunca retrocede.
- Un mensaje sin fecha se considera anterior a cualquier marca, porque las marcas
  solo existen desde esta versión.
- Un contenido guardado ilegible no rompe nada: se empieza sin marcas.

- Verificado: prueba roja primero; después
  `flutter test test/features/chats/chat_read_marks_notifier_test.dart` → 10 de 10.

### Paso 3 — el sello del contador

`lib/features/chats/presentation/widgets/ink_unread_badge.dart`. Círculo de 22 px
con dos tratamientos: relleno con el acento cuando hay mensajes nuevos, y
contorno **punteado** en gris al 45 % de opacidad cuando el número es 0. El trazo
discontinuo se dibuja con un `CustomPainter` propio porque `Border` no ofrece
línea punteada. Sobre 99 muestra `99+`. Describe su estado para lectores de
pantalla ("Sin mensajes nuevos" / "3 mensajes nuevos").

- Verificado: prueba roja primero; después
  `flutter test test/features/chats/ink_unread_badge_test.dart` → 5 de 5.

### Paso 4 — recarga de productos que reemplaza en vez de acumular

Las tarjetas de intercambio resuelven sus productos contra `productsProvider`, así
que el refresco también tiene que volver a pedirlos. `loadNextPage` no sirve: solo
agrega al final, y además se rinde cuando `isLastPage` ya está marcado.
`ProductsNotifier.reloadLoadedPages()` pide una sola página desde `offset: 0` del
tamaño de lo ya cargado (mínimo una página) y **reemplaza** la lista. Si falla,
conserva lo que se veía y expone el error.

Dos expectativas de la prueba estaban mal escritas y se corrigieron contra el
comportamiento correcto: el tamaño pedido nunca baja de una página completa, y una
lista de un solo producto sigue siendo la última página.

- Verificado: `flutter test test/features/products/products_notifier_test.dart`
  → 9 de 9.

### Paso 5 — refresco compartido en las tres listas

Todo lo común vive en
`lib/features/chats/presentation/screens/exchange_list_support.dart`:

- `refreshExchangeData(ref, userId)`: pide en paralelo los intercambios y los
  productos. Las dos cosas, porque las tarjetas resuelven título y portada contra
  `productsProvider` y un refresco a medias dejaría datos viejos.
- `ExchangeListRefresh`: *mixin* para el estado de cada lista. Reúne los
  disparadores que no son el gesto: reanudar la aplicación (con
  `AppLifecycleListener`) y volver desde una pantalla hija (`pushAndRefresh`).
  Tiene una guarda para que dos gestos seguidos no lancen peticiones encimadas.
- `ExchangeRefreshIndicator` y `ScrollableStatus`: el `RefreshIndicator` con los
  colores de la marca, y el envoltorio que deja el mensaje de estado dentro de un
  desplazamiento.

**El detalle que más fácil se pasa por alto:** sin `ScrollableStatus` y sin
`AlwaysScrollableScrollPhysics`, el gesto de arrastrar no existe cuando la lista
está vacía o cabe entera en pantalla, que es justo cuando alguien lo intenta.
Hay una prueba dedicada a eso.

`InkExchangeListScreen` (Enviadas y Recibidas) e `InkChatListScreen` pasaron de
`ConsumerWidget` a `ConsumerStatefulWidget` para poder usar el *mixin*.

### Paso 6 — el sello en la lista de chats, y el chat que se pone al día

`InkExchangeCard` acepta un `badge` opcional. Va dentro del `Transform.rotate`,
en un `Stack` con `clipBehavior: Clip.none` y desplazado `top: -9, right: -9`, así
que se inclina junto con la tarjeta, sobresale como calcomanía y no tapa el número
de la cinta superior. El relleno superior de la lista subió de 18 a 22 para darle
ese aire. La tarjeta sin `badge` se dibuja exactamente igual que antes.

En `chat_screen.dart`:

- el historial de mensajes se puede arrastrar para refrescar; vuelve a pedir
  `join-chat` y espera el `chat-history`, con un tope de 8 segundos para que el
  indicador no quede girando si la respuesta no llega. Sin conexión, avisa y no
  intenta nada;
- la conversación se marca como leída al recibir el historial y con cada mensaje
  nuevo que llega estando dentro.

No se agregó ningún campo de texto ni botón nuevo a esa pantalla, para no romper
las anclas del recorrido Playwright del chat.

### Paso 7 — un solo lugar recarga después de un cambio de estado

Al rechazar, aceptar o cancelar, `InkExchangePreviewScreen` muestra el aviso y
**vuelve** a la bandeja; la bandeja se recarga sola al recibir el control. Lo
mismo al completar o cancelar desde el chat. Se eligió así, y no que cada pantalla
hija recargara por su cuenta, para no encadenar dos refrescos seguidos contra una
API gratuita que además se duerme.

De paso se quitó el `ref.invalidate(chatExchangesProvider)` que había en
`chat_screen.dart`: invalidar reinicia el estado a lista vacía y hacía parpadear
el "Cargando intercambios..." al volver.

### Paso 8 — las marcas se guardan por cuenta, no solo por intercambio

Al revisar el paso 2 apareció un problema real para la demostración: las dos
cuentas `Usuario Demo 1` y `Usuario Demo 2` comparten los mismos intercambios y
pueden usarse en el mismo teléfono. Con la marca guardada solo por intercambio, la
cuenta que entraba después heredaba la lectura de la anterior y veía 0 mensajes
nuevos sin haber leído nada.

La clave de almacenamiento pasó a ser `"<id de cuenta>|<id de intercambio>"`, y
tanto `markReadAt` como `markExchangeAsRead` exigen ahora la cuenta. Hay una
prueba que reproduce exactamente ese escenario de dos cuentas en un teléfono.

### Paso 9 — dónde queda el sello, decidido mirándolo

La primera posición (sobre la esquina, `Offset(9, 9)`) funcionaba bien con el
círculo relleno, pero con el contador en 0 el "0" caía justo encima de la línea de
tinta del borde y no se leía. Se rindieron tres variantes a 390 px con las fuentes
reales y se eligió `Offset(3, 17)`: el sello sube por encima del borde superior,
queda apoyado sobre la cinta y su número cae sobre el papel.

Para que no pise la tarjeta de encima ni su sombra, la lista de chats usa 26 px de
relleno superior y 22 px entre tarjetas, en vez de los 18 y 15 de las bandejas.

**Verificación visual:** se renderizaron las tarjetas a 390×520 con densidad 3 y
las fuentes empaquetadas, en modo claro y oscuro, y se revisaron las imágenes. En
claro, el sello con número es un círculo magenta con sombra dura y el de 0 es un
círculo punteado gris apenas perceptible. En oscuro, el sello con número usa el
contenedor magenta con borde y número en neón —acento pequeño, nunca relleno
grande— y el de 0 casi desaparece contra el papel oscuro sin dejar de notarse.
Ninguno tapa el número de la cinta ni la tarjeta de encima. Las imágenes quedaron
en `build/render_t035/` (fuera de git).

## Verificación final

| Comando | Resultado |
| --- | --- |
| `flutter analyze` | sin hallazgos |
| `flutter test` | 56 de 56 (eran 28 antes de esta tarea) |
| `cd e2e && npm run check:quality` | 8 de 8 controles Node de portabilidad y seguridad |

**Playwright se corrió el 2026-09-21 y dio 1 de 6, pero por una causa anterior a
esta tarea.** El detalle está más abajo, en su propia sección: el rediseño cambió
las pantallas sin actualizar las anclas de los recorridos. El del chat ni siquiera
llega al chat, así que Playwright hoy no valida ni invalida nada de T-035. Esa
cobertura la reemplazó, por ahora, la verificación en teléfono real.

## Lo que queda afuera

- **Tiempo real.** Sigue sin haber aviso inmediato de lo que hace la otra persona.
  Necesitaría una sala de Socket.IO por usuario en NestJS que emita los mensajes
  nuevos y los cambios de estado de todos sus intercambios. Es la continuación
  natural de esta tarea si Marco decide abrir ese frente.
- **Contadores entre dispositivos.** Al ser locales, se reinician si se reinstala
  la aplicación o se entra desde otro teléfono.
- **Sello en las bandejas.** Solo lo llevan las tarjetas de "Intercambio en
  curso". Las solicitudes pendientes todavía no tienen conversación, así que no
  hay nada que contar.

## Verificación en teléfono real (2026-09-21)

Se verificó sobre el Samsung `SM-S938B` (Android 16, 1080×2340), con la sesión de
`tool/desarrollo_visual.dart --plataforma=android` que Marco tenía corriendo contra
la API pública de Render. La app instalada databa de las 16:06 de ese día, es decir
que incluía estos cambios. Se condujo por `adb` y se revisó cada paso por captura.

El recorrido usó los datos demo reales, no datos de prueba:

| Paso | Resultado |
| --- | --- |
| Lista de chats como Usuario Demo 1 | Dos tarjetas de "Intercambio en curso", ambas con el sello en 0 punteado |
| Consulta directa a la API para contrastar | El intercambio de Claymore tiene 3 mensajes, uno de ellos de la otra persona |
| Lista de chats como Usuario Demo 2 | El mismo intercambio muestra **2** |
| Arrastrar hacia abajo | Aparece el indicador con el color de la marca y la lista se desplaza |
| Abrir la conversación | Carga los 3 mensajes reales, con el propio a la derecha |
| Volver a la lista | El sello del intercambio pasó de **2** a **0** sin intervención |

Ese contraste entre las dos cuentas es la verificación más importante de todas,
porque prueba tres cosas a la vez con datos reales:

1. el contador **excluye los mensajes propios** (3 mensajes en total, 2 contados);
2. las **marcas son por cuenta**: Demo 1 veía 0 porque ya había abierto ese chat en
   ese mismo teléfono, y Demo 2 veía 2 porque nunca lo había abierto. Es
   exactamente el escenario del paso 8, comprobado ahora en el dispositivo;
3. abrir la conversación marca como leído y **volver recarga la lista sola**.

Capturas en `build/telefono_t035/` (fuera de git). La sesión del teléfono se
devolvió a Usuario Demo 1, como estaba.

Al pasar quedó a la vista que la pantalla de acceso y la cabecera del chat siguen
con el diseño anterior: son dos de las cuatro pantallas que faltan del rediseño.

## Playwright: la suite está rota desde antes de esta tarea

Al correr `npm test` en `e2e/` el 2026-09-21 el resultado fue **1 de 6**. La
investigación descartó que la causa sea T-035:

- Ningún commit del rediseño tocó `e2e/`: `git log 678907d..HEAD -- e2e/` no
  devuelve nada. Playwright no se corría desde el 2026-09-15 (`fa1858e`).
- El commit `addc5ec` cambió el router de `DiscoverScreen` a `InkDiscoverScreen` y
  de `ProductsScreen` a `InkProductsScreen`. Las anclas
  `'¡Cambia y descubre!'` y `'Todavía no has publicado productos.'` solo existen en
  `discover_screen.dart` y `products_screen.dart`, que ya no se renderizan.
- El recorrido del chat (`full-journey.spec.js:221`) **muere en la pantalla de
  descubrir, antes de llegar al chat**. Es decir que Playwright hoy no dice nada,
  ni bueno ni malo, sobre el chat ni sobre esta tarea.

Los cinco fallos y dónde ocurren:

| Recorrido | Ancla que falla |
| --- | --- |
| `:221` dos sesiones conversan | `heading '¡Cambia y descubre!'` no existe |
| `:560` editar y eliminar producto | `'Eliminar producto'` existe pero está oculto |
| `:651` error de red en el acceso | agota el tiempo llenando `'El correo de tu cuenta'` |
| `:672` fallos de listas y vacíos | `'Todavía no has publicado productos.'` no existe |
| `:800` cancelar y rechazar | agota el tiempo llenando `'El correo de tu cuenta'` |

Los tres primeros tipos son consecuencia directa del cambio de pantallas. Los dos
del acceso son distintos: esa etiqueta **sí** existe en `login_screen.dart`, y otros
recorridos sí logran iniciar sesión, así que parece un problema de tiempos o de
paralelismo, o del cambio sin commitear que volvió `MyFieldText` un `StatefulWidget`
para seguir el foco. Queda por determinar.

Arreglarlo es una tarea aparte, **T-037** en el tablero. Conviene decidir su orden
respecto de las cuatro pantallas que faltan rediseñar, porque volver a escribir las
anclas dos veces sería trabajo perdido.
