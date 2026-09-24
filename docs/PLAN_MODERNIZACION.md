# Plan maestro de modernización — cliente Flutter

*De Android 13 a Android 16, y de Flutter 3.16.8 a 3.47.x.*

**Fecha:** 2026-09-24 · **Estado:** **completado** — las cinco etapas cerradas y
verificadas sobre un teléfono real el mismo día.
**Objetivo decidido por Marco el 2026-09-24:** llegar a **Flutter 3.47.x**, la
última estable, y desde ahí a **`targetSdk` 36 (Android 16)**.
**Resultado medido en el APK:** Flutter 3.47.5, `targetSdkVersion: 36`. El
registro de cada etapa está en la sección 8 bis.

> **Ajuste de alcance del 2026-09-24, posterior a la primera versión de este
> plan.** El objetivo inmediato es **Android 16, no 17**: el salto es del 13 al
> 16. Android 17 **no se abandona** —se le sigue acumulando documentación en el
> anexo para que el paso siguiente sea barato—, pero no es lo que se ejecuta
> ahora. La razón es buena: **Android 16 se puede verificar hoy sobre el teléfono
> real**, que corre exactamente esa versión, mientras que la 17 no se puede
> comprobar con el equipo disponible. Y hay una ventana: cuando el aparato se
> actualice, esa posibilidad de verificar contra Android 16 **se pierde**.

Este documento es el **plan**. Las mediciones técnicas previas siguen vivas y no
se repiten aquí: viven en [`MIGRACION_ANDROID_17.md`](MIGRACION_ANDROID_17.md),
que queda intacto y pasa a ser el **anexo técnico** de este plan.

> **Por qué un documento nuevo y no una sección de `ai-handoff/MASTER_PLAN.md`.**
> El `MASTER_PLAN` es un índice de estado: dice dónde está todo hoy. Esto es una
> campaña de varias etapas con puertas de entrada y salida, que se ejecutará a lo
> largo de varias sesiones y probablemente por más de una herramienta. Además
> `ai-handoff/` **no está versionada en git** por decisión del 2026-09-21, así
> que no tiene respaldo remoto; un plan de este tamaño no debería vivir solo en
> un disco. Este archivo sí se versiona, junto al anexo técnico que ya está aquí.
> `MASTER_PLAN.md` y `TASKS_BOARD.md` lo apuntan.

---

## 1. El diagnóstico, medido el 2026-09-24

Todo lo de esta sección se obtuvo ejecutando algo. Lo que viene de documentación
externa está marcado y citado en la sección 2.

### Dónde estamos

| Pieza | Valor | Cómo se supo |
| --- | --- | --- |
| Flutter / Dart | **3.16.8 / 3.2.5**, revisión `67457e669f` del **2024-01-16** | `flutter doctor -v` |
| `targetSdkVersion` efectivo | **33 — Android 13** | `flutter.groovy:55` y `gradle_utils.dart:43`; el módulo usa `flutter.targetSdkVersion`, no un número propio |
| `minSdkVersion` efectivo | **19** (Android 4.4) | mismas fuentes |
| `compileSdkVersion` | 34, escrito a mano | `android/app/build.gradle` |
| Gradle / AGP / Kotlin | **7.5 / 7.3.1 / 1.7.10** | `gradle-wrapper.properties` y `android/build.gradle` |
| Java del proyecto | `sourceCompatibility`, `targetCompatibility` y `jvmTarget` en **1.8** | `android/app/build.gradle` |
| JDK para compilar | Temurin **17.0.13** (`JAVA_HOME`) | `java -version`. Android Studio trae un 21 aparte, que **no** sirve: con JDK 21 la cadena falla en D8 |
| Android SDK instalado | plataforma **36**, build-tools 36.0.0 | `flutter doctor -v` |
| Bandera heredada | `android.enableJetifier=true` | `android/gradle.properties`. Es de la era de las *support libraries*; hoy solo frena la compilación |
| Tamaño del cliente | 134 archivos Dart, **14.721 líneas**, 23 archivos de prueba | `find` + `wc` |
| Red de seguridad | **82 pruebas Flutter**, **8 recorridos Playwright**, CI en verde | `PROGRESS_LOG.md` y `gh run list` |
| Flutter fijado en CI | `3.16.8` en **dos** lugares | `.github/workflows/*.yml:17` y `:110` |

### El teléfono de pruebas, medido hoy

| Dato | Valor |
| --- | --- |
| Modelo | `SM-S938B` (Galaxy S25 Ultra), serie `R5GL416C8ST`, conectado por USB |
| Android | **16**, SDK **36** |
| Pantalla | 1080 × 2340, densidad 450 |
| **Ancho mínimo** | **384 dp** (1080 ÷ 2,8125) |

Ese último número importa y se explica en la sección 2.

### El atraso de las dependencias, y la columna que casi nadie mira

`flutter pub outdated` tiene una columna **Resolvable**: lo que se puede
actualizar **sin tocar Flutter**. Ahí está la palanca de todo este plan.

| Paquete | Hoy | Alcanzable **ya**, con Flutter 3.16.8 | Última |
| --- | --- | --- | --- |
| `go_router` | 10.2.0 | **14.2.3** | 18.0.1 |
| `image_picker` | 0.8.7 (fijado) | **1.0.0** | 1.2.3 |
| `socket_io_client` | 2.0.3+1 | **3.0.2** | 3.1.6 |
| `formz` | 0.5.0 (fijado) | **0.7.0** | 0.8.1 |
| `flutter_dotenv` | 5.2.1 | **6.0.1** | 6.0.1 |
| `flutter_riverpod` | 2.6.1 | — | 3.4.3 |
| `flutter_secure_storage` | 9.2.4 | — | 11.2.0 |
| `get` | 4.6.6 | — | 4.7.3 |

Dos paquetes transitivos están **descontinuados**: `flutter_secure_storage_macos`
y `js`. Ninguno afecta a Android; se resuelven solos al subir.

### El daño real en el código: mucho menor de lo que parece

Se contaron los usos de las APIs que Flutter moderno ya retiró o deprecó, sobre
las 14.721 líneas:

| API | Usos | Qué cuesta |
| --- | --- | --- |
| `withOpacity` | 18 | Renombrar a `.withValues(alpha: …)`. Mecánico |
| `MaterialState` / `MaterialStateProperty` | 11 | Renombrar a `WidgetState…`. Mecánico |
| `background:` / `onBackground` de `ColorScheme` | 4 | Migrar a `surface` / `onSurface`. Cuidado: toca el tema |
| `WillPopScope`, `RaisedButton`, `FlatButton`, `textScaleFactor`, `accentColor`, `DiagnosticableMixin` | **0** | — |

**Unos 33 puntos en total, y ninguno de los que duelen de verdad.** La conclusión
es importante y conviene no perderla: **la aplicación no está envejecida, está
clavada.** Está escrita con patrones actuales sobre un SDK viejo. Eso es un
problema mucho más barato que el que parecía.

### El backend no tiene este problema

Para que quede el contraste: NestJS **12.0.1** contra 12.1.0 disponible, sobre
Node **22.12.0**. Está prácticamente al día. **Toda la deuda de modernización
está del lado del cliente**, y este plan no necesita tocar la API.

---

## 2. Lo que exige Android 16, y lo que queda anotado de la 17

**Android 16 es API 36.** Es el objetivo de este plan y es la versión que corre
el teléfono de pruebas, así que **todo lo que exige se puede medir**, no suponer.

**Android 17 es API 37**, disponible de forma general desde el **2026-06-16**.
Queda para después; lo que se sepa de ella se anota en el anexo.

### La noticia que descomprime todo: no hay fecha límite

Ni Android 16 ni Android 17 **definen un `targetSdk` mínimo para instalar o
ejecutar** una aplicación. Hoy la app apunta a API 33 y funciona; cuando el
S25 Ultra reciba la 17, seguirá funcionando igual. Y como el proyecto no se
publica en Google Play, tampoco corre el plazo de Play.

Esto cambia la naturaleza del trabajo: **es una inversión planificada, no una
urgencia.** Se puede hacer bien, por etapas, con verificación entre medio.

### Las dos exigencias de Android 16 que importan: ya están medidas

Y esta es la mejor noticia del cambio de alcance. El anexo ya midió, **sobre el
teléfono real**, las dos exigencias que se temía que descarrilaran todo:

- **Borde a borde obligatorio.** Se activaron en el aparato los interruptores de
  compatibilidad `ENFORCE_EDGE_TO_EDGE` y `DISABLE_OPT_OUT_EDGE_TO_EDGE`, que
  aplican las reglas exactas de `targetSdk` 36 sin cambiarlo. Resultado:
  **0 píxeles** de diferencia en la conversación y 0,149 % en la lista de chats,
  y esa diferencia está en el **centro** de la pantalla, sobre las miniaturas, no
  en los bordes. No rompe nada.
- **Páginas de memoria de 16 KB.** Las cuatro bibliotecas nativas del APK
  declaran `LOAD align = 0x10000`, es decir 64 KB. Cubre de sobra el mínimo.

Queda **una sola** mitad pendiente de ese requisito, y es de empaquetado: en una
compilación de *release* las bibliotecas van sin comprimir y deben quedar
alineadas a 16 KB. Eso se resuelve con la cadena de herramientas nueva y es la
puerta de salida de la Etapa 3.

### Anotado para Android 17, no para ahora

De los cambios de Android 17 que afectan a **todas** las aplicaciones sin
importar el `targetSdk`, los que rozarán este proyecto cuando llegue el momento:

- **Límites de memoria RAM por dispositivo.** El sistema puede matar apps que se
  pasan. Se detecta leyendo `"MemoryLimiter:AnonSwap"` en
  `ApplicationExitInfo.getDescription()`. Para una app Flutter de este tamaño no
  debería ser un problema, pero conviene saber cómo se ve el síntoma.
- **`usesCleartextTraffic` queda en camino de deprecación**, en favor de un
  archivo de configuración de seguridad de red. El proyecto lo usa en
  `android/app/src/debug/AndroidManifest.xml` para hablar con la API local.
  Es **solo depuración**, así que el riesgo es bajo, pero es deuda anotada.
- **La visibilidad del teclado ya no se restaura sola tras rotar.** Vale la pena
  probar los formularios rotando el teléfono después de migrar.

Y la más ruidosa de la 17, que además **no aplicará a este teléfono**: elimina
la posibilidad de renunciar a la interfaz adaptable en pantallas grandes, pero
solo sobre dispositivos de **ancho mínimo mayor a 600 dp**. **El S25 Ultra mide
384 dp**, así que queda holgadamente fuera. Si algún día la app corriera en una
tablet o un plegable, habría que revisarla.

### Lo que tampoco bloquea

De los 67 paquetes del `pubspec.lock` solo 4 traen módulo Android y los 4
declaran `namespace`, así que **las dependencias no bloquean AGP 8**.

Eso ya está medido y no se vuelve a medir.

---

## 3. La regla de orden: por qué esto va antes que construir

Marco lo planteó así el 2026-09-24: *"siento que estamos avanzando y avanzando y
mientras más lo hagamos más problemas tendremos con la modernización futura"*.

Hay que ser preciso, porque la frase es correcta pero no por la razón obvia:

- **Del lado del código Dart, el efecto es pequeño.** Son 33 puntos en 14.721
  líneas. Escribir pantallas nuevas agrega algunos `withOpacity` más y poco más.
- **Del lado de las dependencias nativas, el efecto es grande.** Cada paquete con
  módulo Android que entra al proyecto es un actor más en la migración de Gradle,
  con su propio calendario de versiones y sus propios requisitos de AGP.

De ahí sale la consecuencia concreta, y obliga a corregir la recomendación del
documento de notificaciones push escrito ayer:

> **Firebase Cloud Messaging no puede ir primero.** Meter una dependencia nativa
> de Android justo antes de rehacer la cadena Gradle significa hacer esa
> migración *con Firebase adentro*, coordinando a la vez el plugin
> `com.google.gms:google-services`, el BoM de Firebase y el salto de AGP. Es
> estrictamente más difícil que hacerla sin él. Y el riesgo que el documento de
> push marcaba como "número uno" —que `google-services` no compile con Gradle 7.5
> y AGP 7.3.1— **desaparece solo** si primero se moderniza: sobre Gradle 9 y la
> última versión del plugin, el problema no existe.

Modernizar primero no retrasa el push: lo abarata y le quita su único riesgo
bloqueante.

### El 28 de septiembre juega a favor

El anexo técnico dice, textual, que lo que exige la 17 *"no se puede comprobar
con el equipo que hay a mano"*, porque el teléfono está en Android 16. Cuando
llegue la actualización, ese impedimento desaparece y la Etapa 5 pasa a ser
verificable sobre un dispositivo real. **La fecha no es una amenaza, es la
llegada del instrumento de medición que faltaba.**

---

## 4. El plan, en cinco etapas

Cada etapa tiene una **puerta de salida**: no se empieza la siguiente sin haberla
pasado. Todas ocurren en una **rama propia** del cliente, `mejora/modernizacion`,
que no se mezcla con trabajo de interfaz.

### Etapa 0 — Punto de guardado y línea base

**Objetivo:** poder volver atrás sin dudas y saber contra qué se compara.

1. Confirmar que `main` y `mejora/calidad-portafolio` están en el mismo commit,
   limpios y publicados. Hoy lo están, en `fe29fcf`.
2. Crear la rama `mejora/modernizacion` desde ahí.
3. Correr **la matriz completa** (sección 5) y **guardar la salida**. Ese es el
   punto de comparación de todo lo que sigue.
4. Grabar los tres flujos Android por nombre accesible
   (`tool/ejecutar_flujo_por_nombres.dart`) sobre el teléfono, como evidencia
   visual del "antes".

**Puerta de salida:** matriz en verde y evidencia guardada.

---

### Etapa 1 — Pagar las dependencias que ya son alcanzables

**Objetivo:** reducir la superficie del salto de SDK antes de darlo. **Esta es la
etapa que convierte un salto aterrador en varios cambios aburridos.**

Se hace **un paquete por commit**, en este orden, de menor a mayor riesgo:

| Orden | Paquete | A | Por qué este orden |
| --- | --- | --- | --- |
| 1 | `flutter_dotenv` | 6.0.1 | Superficie mínima: se usa al arrancar y poco más |
| 2 | `formz` | 0.7.0 | Solo valida formularios; las pruebas de widget lo cubren |
| 3 | `socket_io_client` | 3.0.2 | Riesgo medio: toca el chat. Lo vigilan el recorrido Playwright del chat y las pruebas del gateway |
| 4 | `image_picker` | 1.0.0 | Cambia la API de retorno. Toca subir fotos de productos |
| 5 | **`go_router`** | 14.2.3 | **El grande.** Cuatro versiones mayores. Toca toda la navegación |

Para `go_router` conviene una precaución extra: es el único cuyo fallo puede ser
silencioso —una ruta que deja de resolver no rompe la compilación, rompe la
navegación— y por eso los 8 recorridos Playwright y los tres flujos Android son
la verificación que manda, no las pruebas unitarias.

**Puerta de salida:** matriz completa en verde después de **cada** paquete, no al
final. Si uno falla, se revierte solo ese commit y se anota por qué.

---

### Etapa 2 — El salto de Flutter a 3.47.x

**Objetivo:** salir de enero de 2024.

1. Instalar 3.47.x **sin borrar** la instalación actual, para poder volver.
2. `flutter pub upgrade --major-versions` y resolver lo que quede
   (`flutter_riverpod` a 3.x, `flutter_secure_storage` a 11.x y `get` a 4.7.3
   entran recién aquí).
3. Corregir los **~33 puntos** ya contados. Los 29 de `withOpacity` y
   `MaterialState` son búsqueda y reemplazo; los 4 de `ColorScheme` tocan el tema
   y piden revisión visual en los dos modos.
4. Subir Flutter en CI: **dos** lugares en `.github/workflows/`.
5. Revisar el aviso anotado en el anexo: `InputDecoration.hint` ya existe en
   Flutter moderno, así que el rodeo de `my_field_text.dart` se puede simplificar.

**Riesgo real de esta etapa:** el rediseño "Tinta y Neón" es un tema propio,
grande y cuidado. Los cambios de `ColorScheme` y de Material 3 entre 3.16 y 3.47
son justo los que pueden mover colores y tipografías sin romper nada. **La
verificación que manda aquí es visual y en los dos modos**, no la compilación.

**Puerta de salida:** matriz completa en verde, **más** una comparación visual
contra las capturas de la Etapa 0, pantalla por pantalla, en modo claro y oscuro.

---

### Etapa 3 — AGP, Gradle, Java y Kotlin

**Objetivo:** poner la cadena de compilación al día.

**El método correcto, y esto evita adivinar versiones:** generar un proyecto
nuevo con `flutter create` usando 3.47.x y **comparar su carpeta `android/`
contra la nuestra**. La plantilla oficial de esa versión dice exactamente qué
AGP, qué Gradle, qué Kotlin y qué Java corresponden. No se copian números de
un blog ni de este documento.

Lo que ya se sabe que hay que hacer:

- Subir `sourceCompatibility`, `targetCompatibility` y `jvmTarget` de **1.8 a 17**.
- **Borrar `android.enableJetifier=true`.** Es de la era de las *support
  libraries*, ya no hace falta y solo alarga cada compilación.
- Migrar la declaración de plugins al bloque `plugins {}`, que es como lo hacen
  AGP 8 y posteriores.
- Revisar qué JDK exige la cadena nueva. Hoy la regla es "JDK 17 obligatorio,
  con 21 falla en D8"; con AGP moderno eso puede cambiar, y si cambia hay que
  **actualizar `PRECAUCIONES.md`**, porque esa restricción está escrita ahí.

**Puerta de salida:** matriz completa, **más** un APK de *release* firmado que
instale y arranque en el teléfono. El de depuración no basta: la alineación a
16 KB del empaquetado solo se verifica en release, y eso quedó explícitamente
pendiente en el anexo.

---

### Etapa 4 — `compileSdk` y `targetSdk` a 36

**Objetivo:** apuntar a Android 16. Es el paso más corto del plan, y solo se
puede dar cuando los tres anteriores están cerrados.

1. `compileSdk = 36` y `targetSdk = 36`, **explícitos**, no heredados de Flutter.
2. **No hay que instalar nada**: la plataforma 36 y las build-tools 36.0.0 ya
   están en este computador, comprobado con `flutter doctor -v`. Con el objetivo
   37 habría habido que descargar la plataforma nueva; con el 36 no.
3. Revisar el `minSdkVersion`: hoy es **19**, un valor absurdo heredado de
   Flutter 3.16. Flutter 3.47 lo sube solo; conviene dejarlo explícito y no
   heredado, para que no vuelva a sorprender.
4. Repasar la lista de cambios de comportamiento de API 36 contra la app.

**Puerta de salida:** matriz completa más APK de release en el teléfono.

---

### Etapa 5 — Verificación sobre Android 16 real

**Objetivo:** comprobar, no suponer. **Se puede hacer ya**, porque el S25 Ultra
corre Android 16 hoy mismo. Y conviene hacerlo **antes** de que reciba la
actualización a la 17, porque después esta verificación deja de ser posible.

1. Confirmar la versión del aparato: `adb shell getprop ro.build.version.sdk`
   debe devolver **36**.
2. Los tres flujos por nombre accesible, de punta a punta.
3. **Rotar el teléfono en cada formulario**, por el cambio de visibilidad del
   teclado.
4. Subir una foto de producto: es el camino que toca permisos y cámara, y es lo
   que más se mueve entre versiones de Android.
5. Volcar el árbol de accesibilidad con `uiautomator dump` y compararlo con el de
   la Etapa 0. Es la misma técnica que levantó T-040 y T-043.
6. Comprobar que el borde a borde sigue sin romper nada, ahora con `targetSdk`
   36 **de verdad** y no simulado con los interruptores de compatibilidad. Es la
   confirmación directa de lo que el anexo midió por aproximación.

**Puerta de salida:** los tres flujos completos sobre Android 16 con `targetSdk`
36, con evidencia. **Recién ahí la migración está hecha.**

### Después: Android 17

Fuera del alcance de este plan, pero no del proyecto. Cuando el teléfono reciba
la 17, el trabajo restante es corto porque todo lo caro ya estará hecho: subir
`compileSdk` y `targetSdk` a 37, instalar la plataforma 37 y repasar la lista de
cambios de comportamiento que el anexo va acumulando. Ese es justamente el
sentido de seguir documentando la 17 mientras se ejecuta la 16.

---

## 5. La matriz de verificación entre etapas

La misma en todas, sin excepciones. Está en
`ai-handoff/ENTORNO_Y_VERIFICACION.md`; se resume aquí para que el plan se baste
a sí mismo:

| Control | Referencia actual |
| --- | --- |
| `flutter analyze` | sin hallazgos |
| `flutter test` | **82 de 82** |
| Controles Node de portabilidad y seguridad | 8 de 8 |
| `flutter build web --release` | correcto |
| `flutter build apk --debug` | correcto |
| Playwright | **8 de 8** — con `E2E_BROWSER_EXECUTABLE` apuntando al Chrome del sistema, porque este computador no puede descargar el navegador de Playwright |
| API sin tocar | 52 de 52, para descartar que el cliente rompió el contrato |

**Dos reglas que ya se pagaron caro en este proyecto y aquí siguen valiendo:**

- **Una prueba que pasa puede estar pasando por suerte.** Antes de confiar en una
  corrección, rómpela a propósito y comprueba que la prueba falla. Fue la
  disciplina que cerró T-026 y T-042.
- **CI y local no son intercambiables.** El recorrido del chat falla en CI y casi
  nunca en local, porque CI usa el Chromium de Playwright sin interfaz y este
  computador usa Chrome real. Entre etapa y etapa conviene mirar los dos.

---

## 6. Riesgos

### Medidos, y no bloquean

| Riesgo | Estado |
| --- | --- |
| Plugins sin `namespace` frenando AGP 8 | **Descartado.** Solo 4 de 67 traen módulo Android y los 4 lo declaran |
| Bibliotecas nativas sin alinear a 16 KB | **Descartado en el archivo.** Las 4 declaran `align = 0x10000` |
| Borde a borde obligatorio | **Descartado.** 0 píxeles de diferencia en la conversación; 0,149 % en la lista de chats, y esa diferencia está en el centro de la pantalla, no en los bordes |
| Interfaz adaptable de Android 17 | **No aplica.** El teléfono mide 384 dp, el umbral es 600 dp |
| Código lleno de APIs muertas | **Descartado.** 33 puntos, ninguno de los graves |

### Abiertos, y hay que vigilarlos

| Riesgo | Por qué | Mitigación |
| --- | --- | --- |
| **El tema visual se mueve solo** | El rediseño es un `ThemeData` grande y cuidado; entre 3.16 y 3.47 cambiaron los valores por defecto de Material 3 y `ColorScheme` | Capturas de la Etapa 0 y comparación pantalla por pantalla en ambos modos |
| **`go_router` rompe en silencio** | Una ruta que deja de resolver no falla al compilar | Los 8 recorridos Playwright y los 3 flujos Android mandan sobre las pruebas unitarias |
| **La regla del JDK puede cambiar** | Hoy "17 obligatorio, con 21 falla en D8". Con AGP moderno puede invertirse | Si cambia, actualizar `PRECAUCIONES.md` en el mismo commit |
| **Alineación de 16 KB en release** | Solo se midió sobre un APK de depuración | Puerta de salida de la Etapa 3: APK de release firmado |
| **Ventana en que la app no compila** | Es una migración de la cadena completa | Rama propia, punto de guardado limpio, y nada de interfaz mezclado |
| **Límite de memoria de Android 17** | Es nuevo y aplica sin importar el `targetSdk` | Paso 6 de la Etapa 5 |

---

## 7. Qué pasa con las notificaciones push

Quedan **después** de la Etapa 4, por la razón de la sección 3. El documento
[`DISENO_NOTIFICACIONES_PUSH.md`](DISENO_NOTIFICACIONES_PUSH.md) sigue vigente en
todo lo demás, con dos ajustes que este plan introduce:

1. **Su "riesgo número uno" se disuelve.** Ya no hay que averiguar si
   `com.google.gms:google-services` 4.3.15 convive con Gradle 7.5 y AGP 7.3.1:
   sobre la cadena nueva se usa la versión actual del plugin y el problema no
   existe.
2. **Su recomendación se mantiene y se refuerza.** Empezar por notificaciones
   locales sigue siendo lo correcto, y ahora además no agrega ninguna dependencia
   nativa antes de la migración: `flutter_local_notifications` sí trae módulo
   Android, así que **también conviene dejarlo para después de la Etapa 3**.

Es decir: durante la modernización, **no entra ninguna dependencia nativa nueva.**
Es la única restricción que este plan le impone al resto del trabajo.

---

## 8. Qué no entra en este plan

- **El backend.** Está al día (NestJS 12.0.1 contra 12.1.0, Node 22) y no
  necesita nada. Subirlo sería trabajo sin problema que resolver.
- **iOS, macOS, Linux y Windows.** Las carpetas existen, pero el alcance del
  proyecto es Android y Web.
- **Rediseño o funcionalidad nueva.** Esta rama no toca interfaz. Mezclar las dos
  causas es exactamente lo que hizo difícil diagnosticar T-040, donde un síntoma
  visible pertenecía a otro defecto.
- **Recalibrar los macros Android por coordenadas.** Ya están resueltos por otro
  camino: `tool/ejecutar_flujo_por_nombres.dart` apunta por nombre accesible y no
  contiene ninguna coordenada, así que sobrevive a esta migración sin tocarse.

---

## 8 bis. Registro de ejecución

Se agrega al cerrar cada etapa. Solo entra aquí lo **medido**.

### Etapa 0 — cerrada el 2026-09-24

Rama `mejora/modernizacion` creada desde `fe29fcf`. Línea base:

| Control | Resultado |
| --- | --- |
| `flutter analyze` | sin hallazgos |
| `flutter test` | **82 / 82** |
| `flutter build web --release` | correcto |
| `flutter build apk --debug` | correcto |
| Controles Node | **8 / 8** |
| Playwright | **8 / 8** en 2,5 min |

Además se capturó un instrumento que no existía y que es el que va a detectar la
deriva del tema en la Etapa 2: **un volcado de los valores resueltos de ambos
temas**, 90 líneas con cada color del `ColorScheme`, los colores sueltos de
`ThemeData`, los temas de `AppBar`, `Drawer`, `SnackBar` y `Divider`, y los
quince estilos del `TextTheme` con familia, tamaño, peso, altura y espaciado.
Se compara con un `diff` línea por línea después del salto, lo que dice
**exactamente** qué valor cambió, en vez de obligar a mirar capturas y adivinar.
Se obtiene con una prueba temporal que se borra al terminar la etapa.

**Salvedad honesta:** la evidencia en el teléfono no se pudo tomar. El aparato
estaba conectado al empezar la sesión —se le leyeron modelo, versión, tamaño y
densidad— pero se desconectó del USB antes de poder correr los flujos, y `adb
devices` dejó de verlo. Se toma en la Etapa 5.

### Etapa 1 — cerrada el 2026-09-24

Cinco paquetes, **cada uno con la matriz completa en verde antes de pasar al
siguiente**, tal como pedía el plan.

| Orden | Paquete | De | A | Cambios de código que exigió |
| --- | --- | --- | --- | --- |
| 1 | `flutter_dotenv` | 5.1.0 | **6.0.1** | **Uno.** `dotenv.testLoad(fileInput:)` se retiró; su reemplazo es `loadFromString(envString:)`. Lo usaba una prueba del socket |
| 2 | `formz` | 0.5.0 | **0.7.0** | Ninguno, con 25 usos en `lib/` |
| 3 | `socket_io_client` | 2.0.3+1 | **3.0.2** | Ninguno |
| 4 | `image_picker` | 0.8.7 | **1.0.8** | Ninguno |
| 5 | `go_router` | 10.2.0 | **14.2.3** | Ninguno |

**Resultado total de la etapa: 10 líneas de `pubspec.yaml` y 7 de un archivo de
prueba.** Cinco actualizaciones mayores, incluido un salto de cuatro versiones
mayores de `go_router`.

Tres cosas que conviene retener:

- **`go_router` salió gratis porque el código ya estaba al día.** Antes de
  tocarlo se hizo el inventario de las APIs que esa biblioteca rompió entre la 10
  y la 14, y el resultado fue **cero usos** de `state.location`, `state.params`,
  `state.queryParams`, `setUrlPathStrategy`, `ShellRoute` y `GoRouteData`. Los 11
  usos de parámetros de ruta ya eran `pathParameters`, la forma nueva. Es la
  confirmación práctica de lo que decía el diagnóstico: la aplicación no estaba
  envejecida, estaba clavada.
- **El riesgo del socket se comprobó donde correspondía.** `socket_io_client` 3
  compiló sin una sola queja, pero eso no prueba nada: lo que importa es que el
  cliente y el servidor sigan hablando el mismo protocolo. Lo demuestran los dos
  recorridos que tocan el socket de verdad —dos sesiones que publican,
  intercambian, conversan **y se reconectan** (1,6 min), y el aviso a quien
  **no** tiene la conversación abierta—, verdes después del cambio.
- **Un aviso del IDE mintió.** Tras migrar `testLoad`, el analizador del editor
  marcó `loadFromString` como inexistente. Era caché de la versión anterior del
  paquete: `flutter analyze` en la terminal no encontró nada y las 83 pruebas
  pasaron. Cuando el editor y la herramienta de línea de comandos discrepen,
  manda la segunda.

### Etapas 2, 3 y 4 — cerradas el 2026-09-24

Se cerraron juntas porque **no se podían separar**: Flutter 3.47 ya no admite
aplicar sus plugins de Gradle con `apply from:`, así que en cuanto se cambió de
SDK la compilación de Android dejó de funcionar hasta rehacer la cadena entera.
La puerta de salida de la Etapa 2 exigía un APK, y ese APK necesitaba la
Etapa 3. **Conviene corregir el plan en este punto para quien lo repita.**

**Resultado, leído del APK construido y no del archivo de configuración:**

```
targetSdkVersion: 36        (antes 33 — de Android 13 a Android 16)
compileSdkVersion: 36
sdkVersion (minSdk): 24     (antes 19)
platformBuildVersionName: 16
```

**Versiones finales**, todas tomadas de un `flutter create` con 3.47.5 y no de
una elección propia: Flutter **3.47.5** / Dart **3.13.4**, AGP **9.1.0**,
Gradle **9.3.1**, Kotlin **2.4.0**, Java **17** (antes 1.8). El JDK para
compilar sigue siendo el 17, así que esa regla de `PRECAUCIONES.md` no cambió.

**Matriz completa en verde:** análisis sin hallazgos, **82 / 82** pruebas,
build web, APK debug, **8 / 8** controles Node y **8 / 8** recorridos Playwright.
Total del cambio: **34 archivos, +606 / −322**.

#### Lo que costó descubrir

**1. El tema se movía solo, y el volcado de la Etapa 0 lo atrapó.**
De los 90 valores resueltos cambiaron exactamente **dos**, y eran el mismo:
`canvasColor` pasaba de `#FDF9FC` a blanco en claro, y de `#131117` a `#1B1820`
en oscuro. La causa: hasta Flutter 3.16 ese valor salía de
`ColorScheme.background`; ese campo se retiró y el valor por omisión pasó a ser
`surface`. Nada fallaba —ni una prueba, ni una compilación—, el color
simplemente se aclaraba. Se corrigió fijando `canvasColor` explícitamente, y
tras el arreglo el volcado quedó **idéntico** al de Flutter 3.16.8. Sin ese
instrumento, esto se habría publicado sin que nadie lo notara.

**2. Gradle 9 no compilaba ni la plantilla oficial de Flutter.** El síntoma era
`Unresolved reference 'run'` sobre la propia biblioteca estándar de Kotlin. Se
aisló con tres experimentos: caché limpia en una carpeta temporal → **funciona**;
borrar solo `caches/9.3.1` → sigue fallando; carpeta nueva y vacía **dentro del
home del usuario** → **funciona**. Conclusión: el problema eran los contenidos
de `~/.gradle`, acumulados desde 2023, y no la ubicación, los permisos ni el
antivirus. Se descartaron por el camino, con evidencia, la integridad de la
distribución (22.164 archivos idénticos a los de la copia limpia), un demonio
del compilador de Kotlin 1.7.10 que seguía vivo desde las compilaciones con la
cadena vieja, y las cachés compartidas `jars-9`, `transforms-3` y
`build-cache-1`, que se restauraron al comprobar que no eran la causa.
**Remedio aplicado:** `~/.gradle` renombrada a `~/.gradle.apartada-20260924` y
en su lugar la caché limpia ya probada. Es un cambio en el computador, no en el
repositorio, y se revierte con un solo renombrado.

**3. `--web-renderer html` ya no existe.** El lanzador de los recorridos lo
pasaba en `e2e/scripts/prepare-environment.js`. Flutter retiró el renderizador
HTML, así que la web se compila con CanvasKit y la bandera sobra.

**4. Y eso rompió 6 de los 8 recorridos, por una razón interesante.** Con el
renderizador HTML, Flutter ponía `aria-label` incluso en los textos sueltos, de
modo que `getByLabel` servía para todo. Con CanvasKit el árbol de accesibilidad
distingue: los campos de formulario llevan `aria-label`, pero un texto corriente
—un mensaje de error, el estado del chat, una burbuja de conversación— viaja
como **contenido** del nodo. Se introdujo el ayudante `porNombreAccesible`, que
acepta las dos formas, y se cambiaron los **60** localizadores de una vez.
Después quedaban 4 fallos por **modo estricto**: Flutter 3.47 agregó
`flt-announcement-host`, una región viva que repite cada mensaje para los
lectores de pantalla, así que todo texto aparecía **dos veces**. Acotar la
búsqueda a `flutter-view` lo resolvió, y además es lo correcto: lo que hay que
comprobar es lo que se ve, no lo que se anuncia.

**5. Una dependencia transitiva usaba el *embedding* v1**, retirado hace años:
`flutter_plugin_android_lifecycle` 2.0.19. Un `pub upgrade` la llevó a 2.0.35.

**6. La compilación incremental de Kotlin falla en este proyecto** con
`Could not close incremental caches … class-fq-name-to-source.tab`, de forma
reproducible y sin depender de limpiar `build/`. Se desactivó con
`kotlin.incremental=false`. Cuesta algo de tiempo de compilación y no cambia el
resultado. **Queda pendiente entender por qué**; la sospecha es la ruta con
espacios (`Escritorio del otro disco`), pero no se comprobó.

#### Paquetes que subieron en estas etapas

`flutter_secure_storage` 9.2.4 → **11.2.0**, `image_picker` 1.0.8 → **1.2.3**,
`web` 0.3.0 → **1.1.1** (la 0.3.0 es incompatible con Dart 3.13, porque
`JSObject` ya no sirve como supertipo, y eso rompía la compilación web), más las
transitivas con `pub upgrade`. De paso desaparecieron los dos paquetes
**descontinuados**, `js` y `flutter_secure_storage_macos`.

**Se dejaron a propósito sin subir** `flutter_riverpod` (2.6.1, hay 3.4.3) y
`get` (4.6.6, hay 4.7.3): ninguno hace falta para el objetivo y Riverpod 3 es
una migración con cambios que rompen. Abrirla aquí habría sido meter un frente
nuevo dentro de otro. Queda anotada como tarea propia.

#### `dart:html` se migró de verdad

`network_status_web.dart` usaba `dart:html`, obsoleta. Se migró a `package:web`
y `dart:js_interop` en vez de silenciar el aviso. El cambio no es de nombre:
allí los eventos llegaban como `Stream` de Dart y aquí hay que registrar y dar
de baja los oyentes a mano, **guardando la misma referencia `JSFunction`** que
se pasó al registrar, porque convertirla dos veces con `.toJS` produce objetos
distintos y `removeEventListener` no encontraría cuál quitar.

### Etapa 5 — cerrada el 2026-09-24

Verificada sobre el **Galaxy SM-S938B con Android 16 (SDK 36)**, con el APK que
declara `targetSdkVersion: 36`. Todo lo de esta sección se midió en el aparato.

| Comprobación | Resultado |
| --- | --- |
| Versión del aparato | Android 16, SDK **36**, 1080×2340 a densidad 450 |
| Instalación y arranque | `targetSdk=36` confirmado por `dumpsys package`; sin excepciones ni ANR |
| Flujos 01, 02 y 03 por nombre accesible | **los tres completos**, sin un solo ajuste de coordenadas |
| Borde a borde real | `mAppBounds` ocupa la pantalla completa: el borde a borde está activo de verdad |
| Rotación | sin excepciones; el chat sigue conectado; **el formulario conserva lo escrito** |
| Selector de fotos | abre `com.google.android.photopicker`, el del sistema, **sin pedir permisos de almacenamiento** |
| Segundo plano y vuelta | sobrevive; **ninguna muerte por el límite de memoria** nuevo |
| Chat | "Chat conectado": el socket funciona con `socket_io_client` 3 sobre la cadena nueva |

#### El borde a borde, medido y no supuesto

Con `targetSdk` 36 la aplicación dibuja bajo las barras del sistema. Lo que
importa es que nada quede tapado, y no lo está:

| Referencia | Posición | Margen libre |
| --- | --- | --- |
| Muesca superior | inset de 96 px | "Volver" empieza en 135 → **39 px** |
| Barra de navegación | y 2205–2340 | campo de mensaje termina en 2177 → **28 px** |
| | | "Enviar mensaje" termina en 2168 → **37 px** |

El sistema reporta además `sw384dp`, que confirma por otra vía el ancho mínimo
de 384 dp calculado al empezar. Es el dato que deja fuera a esta aplicación de
la exigencia de interfaz adaptable de Android 17, que se aplica sobre 600 dp.

#### Una hora perdida que conviene no repetir

El primer intento de los flujos falló en el acceso, y el diagnóstico tardó
porque todo parecía correcto: la API pública respondía `200` en 0,23 s, el
correo y la contraseña **sí** llegaban a los campos —comprobado leyendo
`text=` del volcado de `uiautomator`—, el teclado se cerraba bien y el toque
caía dentro del botón.

La causa era otra: se había usado `--sin-compilar`, y el APK reutilizado se
había construido sin `--dart-define`. Sin ellos la aplicación lee el `.env`
empaquetado, que dice `API_URL=http://localhost:3001/api`. Dentro del teléfono,
`localhost` **es el teléfono**, así que no había servidor al otro lado.

**Regla práctica:** `--sin-compilar` solo sirve cuando el APK instalado se
construyó con el mismo lanzador. Para una verificación de verdad, conviene
dejar que compile él, que es quien pasa las direcciones.

### Ampliación de pruebas — 2026-09-24

Marco pidió cubrir casos borde y atípicos. La suite Flutter pasó de **82 a 145
pruebas**: cuatro archivos nuevos, ninguno reemplaza a los que ya había.

| Archivo nuevo | Pruebas | Qué vigila |
| --- | ---: | --- |
| `test/config/editorial_app_theme_colores_test.dart` | 10 | Los colores del tema, que derivan en silencio al actualizar Flutter |
| `test/config/environment_test.dart` | 15 | La configuración de direcciones, que no tenía **ninguna** prueba |
| `test/features/shared/socket_service_casos_borde_test.dart` | 18 | El ciclo de vida del socket: antes de inicializar, tras desconectar, y los envíos que no deben salir |
| `test/features/shared/inputs_casos_borde_test.dart` | 20 | Los validadores de formulario, incluidas sus limitaciones conocidas |

#### Encontraron dos cosas reales

**Un defecto, corregido.** `Environment.socketUrl` derivaba la dirección del
socket recortando la de la API con
`apiUri.replace(path: '', query: null, fragment: null)`. En Dart, pasar `null` a
`Uri.replace` significa **"conserva lo que había"**, no "bórralo": un `API_URL`
con parámetros dejaba el socket apuntando a `https://servidor?clave=1`. Ahora el
origen se construye desde cero con `Uri(scheme:, host:, port:)`. La prueba falló
antes del arreglo y pasó después, que es la mejor evidencia posible de que
vigila.

**Un defecto menor, corregido después.** `Tomo.validator` hace
`int.tryParse(value.toString()) ?? -1` y luego comprueba `== -1` para detectar
un valor no numérico. Pero el campo ya es un `int`: el análisis nunca falla, y
el **-1 legítimo choca con el valor centinela**. Resultado: el tomo -1 se
reporta como "No tiene formato de número" en vez de "Número de ser igual o mayor
a 0". El tomo igual se rechaza y la API valida aparte, así que solo confunde el
mensaje. Queda fijado el comportamiento real y anotado como **T-054**, para que
sea Marco quien decida si se corrige.

#### Se comprobó que las pruebas vigilan, rompiendo el código a propósito

No basta con que pasen. Se rompió el código y se comprobó que fallan:

- Al quitar `canvasColor: background`, fallaron **exactamente las dos** pruebas
  del lienzo y ninguna otra.
- Al quitar `enableForceNew()`, fallaron dos: la prueba nueva de opciones de
  conexión y la de T-013 que ya existía.

#### Y una prueba propia resultó ser un falso positivo

Vale la pena dejarlo escrito, porque es el motivo por el que esta disciplina
existe. Se había escrito una prueba llamada "rechaza el contenido vacío o en
blanco" para `sendMessage`. **Al borrar del código la guarda `message.isEmpty`,
la prueba siguió pasando.** La razón: `sendMessage` comprueba dos cosas —que el
contenido no esté en blanco y que la conversación esté lista— y sin servidor la
segunda siempre falla, así que el envío devuelve `false` por el otro camino.

La prueba se reescribió por lo que de verdad vigila —que nada sale mientras la
conversación no esté lista— y el archivo lleva una advertencia explicando que la
guarda del contenido vacío no se puede aislar sin una conexión viva, y que la
cubre el recorrido Playwright del chat.

#### Limitaciones que ahora están documentadas, no escondidas

Varias pruebas fijan comportamiento que no es ideal. Se escribieron igual,
porque una limitación anotada es una decisión y una limitación que nadie escribió
es una sorpresa esperando a un usuario:

- El validador de correo **no recorta espacios**: un correo pegado con un
  espacio al final se rechaza por formato, con un mensaje que no lo explica.
- Su dominio de primer nivel admite **solo de 2 a 4 letras**, así que `.museum`
  y `.online` se rechazan.
- **No admite direcciones con etiqueta** (`marco+compras@gmail.com`).
- En cambio **acepta puntos consecutivos**, que no son válidos.
- En la contraseña, los **espacios cuentan para el mínimo de seis**.

#### Actualización del mismo día: la regla del tomo

Horas después, Marco fijó una regla de dominio: **el tomo es el número de
volumen de un manga o manhwa, así que el mínimo es 1**. Como el catálogo también
tiene Ropa, Taza y Otros —donde el 0 significa "no aplica" y las fichas ocultan
la etiqueta—, decidió que el mínimo aplique **solo cuando el tipo es Manga**.
Negativos, nunca, para ningún tipo.

Con eso el defecto del -1 descrito arriba (T-054) **quedó corregido**: se
retiró la comprobación con valor centinela, que era inalcanzable. Al
implementarlo apareció otro defecto, también corregido: `onStockChanged`
validaba el formulario con el tomo **anterior**, porque `state` todavía no se
ha reasignado cuando se evalúan los argumentos de `copyWith`. Se comprobó
devolviéndole el defecto al código: fallan cuatro pruebas.

La suite quedó en **161 pruebas**, con `test/features/products/product_form_tomo_test.dart`
(13) y el grupo del tomo reescrito en `inputs_casos_borde_test.dart`. La API
rechaza además tomos negativos con `@Min(0)`, con una prueba E2E nueva.

---

## 9. Cómo se mantiene este documento

- Al cerrar cada etapa: marcar su puerta de salida, anotar lo que **se midió**
  (no lo que se supuso) y agregar una entrada a `ai-handoff/PROGRESS_LOG.md`.
- Los hallazgos técnicos que aparezcan en el camino van al anexo
  [`MIGRACION_ANDROID_17.md`](MIGRACION_ANDROID_17.md), que ya tiene esa
  costumbre y no se reemplaza.
- Si una etapa resulta más cara de lo previsto, se dice aquí y se replantea el
  alcance. **Un plan que no se corrige deja de ser un plan.**

---

## Fuentes externas consultadas el 2026-09-24

- [Android 17 — cambios de comportamiento para todas las apps](https://developer.android.com/about/versions/17/behavior-changes-all)
- [Android 17 — cambios para apps que apuntan a Android 17](https://developer.android.com/about/versions/17/behavior-changes-17)
- [Android 17 — notas de la versión](https://developer.android.com/about/versions/17/release-notes)
- [Android Developers Blog — Android 17 is here](https://android-developers.googleblog.com/2026/06/Android-17.html)
- [Flutter — novedades de la documentación](https://docs.flutter.dev/release/whats-new)
- [Shorebird — versiones de Flutter](https://docs.shorebird.dev/getting-started/flutter-version/)
