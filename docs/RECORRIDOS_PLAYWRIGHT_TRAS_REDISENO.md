# Reparación de los recorridos Playwright tras el rediseño (T-037)

**Estado:** reparada; queda abierta la intermitencia del chat (T-026). Sin commit · **Fecha:** 2026-09-21 · **Rama:** `mejora/calidad-portafolio` (cliente Flutter)

## Qué pasó

El 2026-09-21, al correr por primera vez los recorridos desde el 2026-09-15, la
suite dio **1 de 6**. La causa no fue la tarea T-035 sino el rediseño completo:

- `git log 678907d..HEAD -- e2e/` no devuelve nada. **Ningún commit del rediseño
  tocó los recorridos.**
- El commit `addc5ec` cambió el router de `DiscoverScreen` a `InkDiscoverScreen` y
  de `ProductsScreen` a `InkProductsScreen`, y los siguientes hicieron lo mismo con
  el resto. Las anclas de los recorridos apuntaban a textos de las pantallas
  viejas, que ya no se renderizan.
- Playwright no se corría desde `fa1858e`, así que el problema se acumuló sin
  avisar durante seis commits de rediseño.

**Lección para el futuro:** mientras dure el rediseño, conviene correr Playwright
al cerrar cada pantalla, no al final. Una pantalla rota se arregla en minutos;
seis pantallas rotas a la vez obligan a este trabajo de arqueología.

## Cómo se distinguió qué arreglar

Para cada ancla rota había que decidir entre corregir la prueba o devolver algo
que el rediseño se había llevado. El criterio fue:

- Si el rediseño **reescribió el texto a propósito y quedó mejor**, manda la
  interfaz y se actualiza la prueba. Es el caso de casi todas: "Proponer
  intercambio" es mejor que "¡Propone un cambio :)!", y "Publicar" mejor que
  "Nuevo producto".
- Si el rediseño **perdió una capacidad de accesibilidad**, se arregla la
  aplicación. Pasó dos veces: el encabezado de Descubrir y el nombre accesible de
  los campos de texto. Las dos tienen su sección más abajo.

Un aviso sobre el método: un primer barrido comparando literales de texto marcó
como rotas las anclas `'Foto 1 de 2'` e `'Imágenes del producto: 2'`. Era un falso
positivo: esas etiquetas se construyen por interpolación
(`'Foto ${index + 1} de ${images.length}'`), así que existen en tiempo de ejecución
aunque el literal no aparezca en el código. **Buscar literales no alcanza para
auditar anclas.**

## Cambio en la aplicación: el encabezado de Descubrir

`InkDiscoverScreen` parte el título en dos `Text` ("Cambia" y "y descubre") por el
salto de línea del diseño. Ninguno de los dos tenía rol de encabezado, así que la
pantalla quedó **sin ningún elemento con rol de título**: un lector de pantalla
leía dos fragmentos sueltos. Se envolvió en
`Semantics(header: true, label: 'Cambia y descubre', excludeSemantics: true)`, que
lo anuncia una sola vez y como encabezado.

Vale la pena revisar en algún momento si el resto de las pantallas `Ink*` ("Chats",
"Recibidas", "Enviadas", "Mi estante") tienen el mismo problema. Aquí solo se
corrigió la que los recorridos necesitaban.

## Anclas actualizadas en los recorridos

| Antes | Ahora | Por qué |
| --- | --- | --- |
| `heading '¡Cambia y descubre!'` | `heading 'Cambia y descubre'` | El título se reescribió sin signos de exclamación |
| `button 'Nuevo producto'` | `button 'Publicar'` | Renombrado en `InkProductsScreen` |
| `button 'Open navigation menu'` | `button 'Abrir menú'` | El menú dejó de ser el `Drawer` de Material |
| `button '¡Propone un cambio :)!'` | `button 'Proponer intercambio'` | Renombrado en `InkOtherProductScreen` |
| `button '¡Sí! Quiero cambiar :D'` | `button 'Sí, enviar'` | Botón del diálogo de confirmación |
| `getByLabel('Confirmación')` | `getByText('Confirmar la propuesta')` | El diálogo ya no lleva esa etiqueta |
| `'Se ha enviado solicitud de conversación :D !'` | `'Propuesta enviada. Te avisaremos cuando respondan.'` | Aviso reescrito |
| `'Todavía no has publicado productos.'` | `/Tu estante está vacío/` | Estado vacío reescrito |
| `/No tienes intercambios aceptados/` | `/[Nn]o tienes intercambios aceptados/` | El texto empieza con "Todavía no tienes…" |
| `getByLabel('Descripción')` | `getByLabel('Descripción', { exact: true })` | Sin `exact` también coincidía con la sección "Descripción y etiquetas" |
| `getByText('Eliminar producto', { exact: true })` | `getByText('Esta publicación se eliminará…')` | El título del diálogo choca con el nombre del botón que lo abre; el texto de contenido es único |

## El campo de texto se quedaba sin nombre accesible

Este fue el hallazgo más importante y el más costoso de acorralar: **no era un
problema de las pruebas sino un defecto de accesibilidad** del cliente. Costó tres
intentos fallidos llegar a la causa real, así que vale la pena dejar escrito el
camino completo.

### Lo que se veía

Dos recorridos fallaban en el acceso, de forma intermitente, mientras otros sí
lograban iniciar sesión. El síntoma se fue moviendo: primero `locator.fill`
agotaba el tiempo, después `locator.inputValue`.

### Los dos intentos que no dieron en el blanco

1. **La carrera de la semántica** (ver la sección siguiente). Era un defecto real y
   se corrigió, pero no era la causa de esto.
2. **`hintText: hasFocus ? null : widget.label`**, que el rediseño había agregado
   junto con el paso de `MyFieldText` a `StatefulWidget`. Como el campo no tenía
   `labelText` ni `Semantics`, su nombre accesible salía del texto de ayuda, y al
   enfocarlo se quedaba sin nombre. Corregirlo **sí** mejoró las cosas, pero los
   recorridos siguieron fallando.

### La evidencia que cerró el caso

En vez de seguir suponiendo, se leyó el árbol de accesibilidad que Playwright
guarda en `error-context.md` al fallar:

```yaml
- textbox [ref=e7]: red-caida@mundo-otaku.test   # sin nombre
- textbox "Contraseña" [active] [ref=e9]         # con nombre
```

El campo **enfocado y vacío** tenía nombre (el arreglo del intento 2 funcionaba);
el campo **con contenido** no tenía ninguno. La causa de fondo era otra: Material
deja de construir el texto de ayuda en cuanto el campo tiene texto, y el nombre
accesible se iba con él.

### El diagnóstico de fondo

**El nombre accesible no puede depender del texto de la decoración.** Ni de
`hintText` ni de `labelText`: Material decide construir o no esos widgets según el
estado del campo —el de ayuda desaparece al escribir, el flotante al enfocar— y la
semántica se va con el widget. Un tercer intento con
`labelText` + `FloatingLabelBehavior.never` lo confirmó: dejó de funcionar en los
dos estados que importaban.

### La corrección

El nombre se declara explícitamente con `Semantics`, y solo cuando el texto de
ayuda no lo está aportando, para que no se anuncie dos veces:

```dart
final hintAportaElNombre = !hasFocus && !_tieneContenido;

return Semantics(
  label: hintAportaElNombre ? null : widget.label,
  child: Container(... TextFormField ...),
);
```

`_tieneContenido` se sigue con un escucha del controlador, igual que ya se seguía
el foco. Queda cubierto por cuatro pruebas de widget en
`test/features/shared/my_field_text_test.dart`: vacío, enfocado, con contenido
previo y mientras se escribe.

**Nota sobre la versión de Flutter:** la solución limpia habría sido pasar el texto
de ayuda como widget con `InputDecoration.hint` envuelto en `ExcludeSemantics`,
pero ese parámetro no existe en Flutter 3.16.8. Es un costo concreto más del atraso
de versión, que ya está anotado como R-20.

**Para cuando se rediseñen el acceso y el registro:** los campos nuevos tienen que
exponer un nombre accesible estable en los cuatro estados. Es un error fácil de
repetir y las pruebas de widget nuevas lo detectan.

## `fill()` no llega a Flutter: hay que teclear

El recorrido de edición guardaba el título **viejo** pese a que el PATCH respondía
200 y aparecía el aviso "Producto actualizado". La captura del fallo mostró el
campo con el texto original: `fill()` había dejado el valor nuevo en el `input` del
DOM, pero el `TextEditingController` del widget nunca se enteró, así que el
formulario envió lo que tenía.

`enterFlutterText` pasó a teclear (`Control+A` y `keyboard.type`), igual que ya
hacía `enterChatMessage` para el chat. Teclear recorre la ruta real de entrada, que
además es lo que hace una persona; `fill` asigna el valor por programa y Flutter
Web no siempre lo ingiere.

**Esto no era un defecto de la aplicación:** una persona escribe, no asigna el
valor del elemento. Vale la pena tenerlo presente, eso sí, para el caso de los
gestores de contraseñas, que sí rellenan campos por programa.

## Controles del rediseño sin rol de botón

Varios elementos tocables del rediseño se construyen con `Material` + `InkWell` sin
declarar `Semantics(button: true)`, así que no se anuncian como botones. El resto
de la aplicación sí lo declara (`InkMenuButton`, `InkHardButton`, el botón "Volver"
de las cabeceras), de modo que era una inconsistencia, no una decisión.

Se corrigieron dos:

- `InkProductRow`, la fila de producto que se toca para elegir qué ofrecer.
- `_ActionButton` de la propuesta ("Rechazar", "Aceptar el cambio", "Cancelar la
  propuesta").

En ambos casos se declara solo `button: true` y el nombre lo sigue aportando el
texto que ya contienen, para no anunciarlo dos veces.

**Queda observado, sin corregir:** la propuesta expone cada panel completo como un
nodo de rol `img` cuyo nombre concatena leyenda, número, título y detalles. Un
lector de pantalla anuncia un bloque de información como si fuera una imagen. No se
tocó porque excede el alcance de reparar los recorridos, pero conviene revisarlo
cuando se retome el rediseño.

## La carrera al habilitar la semántica de Flutter Web

Dos recorridos fallaban al llenar el correo en el acceso, de forma intermitente,
mientras otros sí lograban iniciar sesión. No era el rediseño: era `e2e`.

`enableFlutterAccessibility` esperaba a que se pintara la primera escena y después
consultaba **una sola vez** si existía el botón "Enable accessibility" que Flutter
Web inyecta:

```js
if ((await enableButton.count()) > 0) {
  await enableButton.evaluate((element) => element.click());
}
```

Ese botón aparece unos milisegundos después de la escena. Si la consulta llegaba
antes, la condición daba falso, **la semántica no se activaba nunca** y cualquier
`getByLabel` posterior agotaba su tiempo sin encontrar nada. Que a veces ganara la
carrera y a veces no explica exactamente el patrón intermitente.

La corrección espera el botón (`waitFor({ state: 'attached' })`) en vez de
consultarlo, y recuerda en un `WeakSet` las páginas donde ya se activó, porque el
botón solo existe la primera vez y esperarlo de nuevo costaría el tiempo de espera
completo en cada navegación posterior.

**Esto puede ser también la causa de T-026**, la falla intermitente del recorrido
del chat en CI, que tiene la misma forma: un control que se encuentra pero cuyo
contenido nunca coincide. Queda por confirmar cuando la suite vuelva a estar verde.

### Un error propio: el recuerdo no se invalidaba al recargar

La primera versión de esta corrección guardaba en un `WeakSet` las páginas ya
activadas, para no pagar la espera en cada navegación. Pero una **recarga**
reinicia la semántica de Flutter y vuelve a inyectar el botón, y el recuerdo hacía
que el ayudante se saltara la activación. El recorrido del chat, que recarga a
propósito para comprobar la reconexión, quedaba sin semántica y no encontraba nada.

Se corrigió escuchando el evento `load` de la página para olvidar el recuerdo. Se
escucha `load` y no `framenavigated` a propósito: un cambio de ruta por hash no
reinicia la semántica y no debe invalidar nada.

**Esto reordena lo que se pensaba de T-026.** La falla intermitente del recorrido
del chat en CI ocurría justo después de una recarga, que es el escenario donde la
semántica podía quedar apagada. La corrección de la carrera, más este reinicio, son
candidatos serios a ser su causa. Hace falta verlo en CI varias veces antes de
darlo por cerrado.

## Bitácora

- **Corrida 1 (1/6).** Estado inicial, diagnóstico completo.
- **Corrida 2 (1/6).** Con las 8 anclas de texto actualizadas y el encabezado
  arreglado. No subió el número, pero **los recorridos avanzaron mucho más**: ya
  pasan el acceso y la pantalla de descubrir, y mueren en puntos nuevos y más
  profundos. Eso confirmó que los arreglos servían y dejó a la vista los cuatro
  problemas siguientes.
- **Corrida 3 (2/6).** Con `Descripción` exacto, el diálogo de eliminar anclado a
  su contenido, el vacío de chats y la carrera de la semántica. El recorrido de
  listas vacías quedó verde. Los dos del acceso **seguían fallando**, así que la
  carrera de la semántica no era su causa (o no la única): el síntoma se movió de
  `locator.fill` a `locator.inputValue`, es decir que el campo se encontraba para
  una operación y desaparecía para la siguiente. Esa pista llevó al hallazgo del
  `hintText`.
- **Corrida 4 (2/6).** Con el `hintText` conservado al enfocar. El árbol de
  accesibilidad del fallo mostró que el campo enfocado ya tenía nombre pero el
  campo con contenido no: de ahí salió la causa de fondo.
- **Corrida 5 (3/6).** Con el nombre accesible declarado por `Semantics`. **Los dos
  recorridos del acceso quedaron resueltos.**
- **Corrida 6 (4/6).** Con el arrastre de fotos calculado desde el ancho real de la
  galería, el diálogo de eliminar anclado a su botón y la propuesta anclada al
  título. El deslizamiento de fotos quedó resuelto: los desplazamientos fijos de
  200 y 400 px empezaban fuera de la galería, más angosta tras el rediseño.
- **Corrida 7 (4/6).** Reveló que la propuesta expone cada panel como **un solo
  nodo de imagen** cuyo nombre concatena la leyenda, el número y el título
  (`img "TÚ ENTREGAS 01 Producto ofrecido… Tomo 1 · Shonen…"`), así que el título
  suelto queda oculto detrás. Las anclas pasaron a ese nodo.
- **Corrida 8 (4/6).** Con el rol de botón declarado en `InkProductRow` y en los
  botones de acción de la propuesta. Los dos fallos por "no se encuentra el
  control" quedaron resueltos y aparecieron dos puntos nuevos, más profundos.
- **Corrida 9 (5/6).** Con el tecleo real en lugar de `fill` y el diálogo de la
  propuesta anclado a su botón. Quedó solo el recorrido del chat, fallando tras la
  recarga.
- **Corrida 10 (6/6).** Con el reinicio de la semántica al recargar. **Verde
  completo por primera vez desde el rediseño.**
- **Corrida 11 (5/6).** Misma versión del código, sin cambios. Cayó el paso de
  reconexión del chat: tras la recarga, la primera sesión no recibió el mensaje que
  envió la segunda al volver de estar sin conexión. Es intermitente, no una
  regresión: por eso se corrió de nuevo en vez de dar la tarea por cerrada con una
  sola corrida verde.
- **Corrida 12 (6/6).** Sin cambios respecto de la 11.

**Medición de estabilidad:** tres corridas seguidas sin tocar nada dieron 6/6, 5/6
y 6/6. La intermitencia es de alrededor de **una de cada tres**, siempre en el
mismo paso.

## Lo que queda abierto: la intermitencia del chat (T-026)

Las anclas y la semántica están resueltas, pero **el paso de reconexión del chat
sigue fallando de vez en cuando**, con el mismo código y sin tocar nada entre una
corrida y otra. El síntoma:

```
Locator: getByLabel('Mensaje tras reconexión …')
Error: element(s) not found
```

Es decir, la primera sesión —que se recargó y muestra "Chat conectado"— no recibe
el mensaje que la segunda envía después de recuperar la conexión. `Chat conectado`
es estado del cliente (`isConnected && _joinedChatId == chatId`), así que el
cliente cree estar en la sala; queda por comprobar si el servidor conserva esa
pertenencia después de la reconexión.

Esto es **T-026** y sigue abierto. No se cerró en esta tarea: acorralarlo pide una
sesión propia, mirando el lado del *gateway* además del cliente. Lo que sí cambió
es que ahora se puede investigar, porque el resto del recorrido llega hasta ahí en
vez de morir en la primera pantalla.

## Resultado

| Antes | Después |
| --- | --- |
| 1 de 6 | 6 de 6 (con una intermitencia de ~1 de cada 3 en el paso de reconexión del chat) |

Cambios en la aplicación —los tres son correcciones de accesibilidad, no ajustes
para contentar a las pruebas:

- `ink_discover_screen.dart`: el título recupera su rol de encabezado.
- `my_field_text.dart`: los campos de texto conservan su nombre accesible en los
  cuatro estados, con cuatro pruebas de widget que lo fijan.
- `ink_product_row.dart` y `ink_exchange_preview_screen.dart`: los controles
  tocables se anuncian como botones.

Cambios en los recorridos: once anclas actualizadas a los textos vigentes, el
arrastre de fotos calculado desde el ancho real, el tecleo en lugar de `fill`, y
dos correcciones en el ayudante de accesibilidad (esperar el botón en vez de
consultarlo una vez, y olvidar el recuerdo al recargar).

Verificación al cerrar: `flutter analyze` sin hallazgos, `flutter test` 65 de 65,
`npm run check:quality` 8 de 8, y las tres corridas de Playwright citadas arriba.
Las salidas completas quedaron en `e2e/pw_run10.log`, `pw_run11.log` y
`pw_run12.log` (fuera de git).
