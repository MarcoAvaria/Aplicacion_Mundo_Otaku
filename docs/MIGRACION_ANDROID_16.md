# Notas para migrar a Android 16 (API 36)

**Estado:** notas en preparación, no se ha migrado nada · **Inicio:** 2026-09-21

Este documento reúne lo que hay que saber antes de intentar la migración, y se va
alimentando con cada cosa que aparece mientras se trabaja en otras tareas. No es un
plan aprobado: es el material para decidir cuándo y cómo hacerlo.

## Punto de partida real, medido el 2026-09-21

| Pieza | Versión actual | Dónde |
| --- | --- | --- |
| Flutter / Dart | 3.16.8 / 3.2.5 | fijado también en CI |
| Gradle | 7.5 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android Gradle Plugin | 7.3.1 | `android/build.gradle` |
| Kotlin | 1.7.10 | `android/build.gradle` |
| `compileSdkVersion` | 34 | `android/app/build.gradle` |
| `minSdkVersion` / `targetSdkVersion` | los de Flutter 3.16.8 | `android/app/build.gradle` |
| Java (source/target/jvmTarget) | 1.8 | `android/app/build.gradle` |
| JDK para compilar | **17 obligatorio** | con JDK 21 la cadena falla en D8 |

Android 16 corresponde a **API 36**.

## Lo importante: es una cadena, no un salto suelto

No se puede subir `targetSdkVersion` a 36 y ya. Cada eslabón obliga al siguiente, y
conviene hacerlos en este orden, verificando la matriz completa entre uno y otro:

1. **Flutter.** 3.16.8 es de enero de 2024. Las versiones que dan soporte real a
   Android 15 y 16 (incluido el empaquetado alineado a 16 KB) son muy posteriores.
   Este es el eslabón que arrastra todo lo demás y el más caro: ya está anotado como
   R-20 y pide repetir análisis, pruebas, build web, APK y Playwright en cada etapa.
2. **AGP y Gradle.** `compileSdk` 35 o superior exige AGP 8.x, y AGP 8 exige Gradle
   8.x. Saltar de AGP 7.3.1 a 8.x no es transparente: cambia la forma de declarar
   los plugins, `namespace` pasa a ser obligatorio en el módulo y varias opciones se
   retiran. Es R-10.
3. **JDK y Java.** AGP 8 requiere compilar con JDK 17 —que ya es lo que se usa— pero
   además conviene subir `sourceCompatibility`, `targetCompatibility` y `jvmTarget`
   de 1.8 a 17. Hoy están en 1.8 y eso genera avisos de compatibilidad.
4. **Kotlin.** 1.7.10 se queda corto para AGP 8; hay que subir a 1.9 o a 2.x.
5. **`compileSdk` y `targetSdk` a 36**, recién al final.

## Dos exigencias nuevas que no son solo cambiar un número

- **Páginas de memoria de 16 KB.** Android 15 introdujo dispositivos con páginas de
  16 KB y Android 16 lo vuelve obligatorio para las aplicaciones que apuntan a API
  36 en esos equipos. Toda biblioteca nativa empaquetada tiene que estar alineada.
  En una aplicación Flutter esto depende del motor y de los plugins con código
  nativo, así que se resuelve subiendo Flutter y revisando cada plugin, no tocando
  el Gradle propio. **Hay que verificarlo en un dispositivo o emulador con páginas
  de 16 KB, no basta con que compile.**
- **Borde a borde obligatorio.** Desde Android 15 las aplicaciones que apuntan a API
  35+ se dibujan de borde a borde y la forma de desactivarlo quedó obsoleta en 36.
  Hay que revisar que las pantallas respeten las áreas seguras. **Al 2026-09-21
  esto quedó cubierto en toda la aplicación**: con el cierre del rediseño (T-038 y
  T-039) las cuatro pantallas que faltaban —acceso, registro, verificación de
  sesión y chat— pasaron a usar `SafeArea`, igual que las que ya estaban en la
  dirección "Tinta y Neón". Queda por comprobar en un dispositivo real que no haya
  recortes con la barra de gestos, pero no hay pantallas sin revisar.

## Hallazgos que fueron apareciendo mientras se trabajaba

Cada uno es un costo concreto del atraso, no una molestia teórica.

- **2026-09-21, T-037.** `InputDecoration.hint` (la variante que recibe un widget, y
  que habría permitido envolver el texto de ayuda en `ExcludeSemantics` para que no
  duplicara el nombre accesible del campo) **no existe en Flutter 3.16.8**. Hubo que
  resolverlo con una construcción más larga en `my_field_text.dart`. Al subir
  Flutter, ese código se puede simplificar.

- **2026-09-21, T-026.** El recorrido del chat falla en CI y casi nunca en local.
  La diferencia es el navegador: CI usa el Chromium propio de Playwright en
  *headless* y este computador usa Chrome real. No es un tema de Android, pero sí
  un recordatorio de que **el entorno de CI y el local no son intercambiables** a la
  hora de dar algo por verificado. Cuando se migre, conviene repetir la matriz en
  los dos.

## Lo que hay que preparar antes de empezar

- **Un dispositivo o emulador de prueba con Android 16 y páginas de 16 KB.** El
  teléfono de Marco es un Samsung `SM-S938B` con Android 16, así que sirve para la
  parte de comportamiento; para las páginas de 16 KB hace falta comprobar si ese
  equipo las usa o si se necesita un emulador configurado a propósito.
- **Los AVD disponibles hoy** son `Pixel_7_API_34` y `Mundo_Otaku_2`. `Pixel_7_API_35`
  está listado pero no arranca porque falta su imagen de sistema.
- **La matriz de verificación completa** de `ai-handoff/ENTORNO_Y_VERIFICACION.md`,
  para correrla entre etapa y etapa.
- **Los macros de los flujos Android** (T-021) se recalibran después, no durante: la
  migración no cambia la geometría de la interfaz, pero el rediseño sí, y conviene
  no mezclar las dos causas si algo se rompe.

## Riesgo que conviene nombrar

Esta migración toca la cadena de compilación de Android completa. Es la clase de
cambio que deja la aplicación sin compilar por un rato y que conviene hacer en una
rama propia, con un punto de guardado limpio antes de empezar y sin mezclarla con
trabajo de interfaz.

## Medición del 2026-09-22: los plugins no son el obstáculo

El bloqueo clásico al pasar a AGP 8 son los plugins antiguos: AGP 8 exige que cada
módulo declare `namespace` en su `build.gradle`, y un plugin sin actualizar hace
fallar la compilación entera. Convenía saber cuántos hay **antes** de planificar,
porque un plugin abandonado puede obligar a reemplazarlo y eso cambia el tamaño
del trabajo.

Se comprobó así: se extrajeron los 67 paquetes de `pubspec.lock` con su versión
exacta, y de cada uno se buscó `android/build.gradle` en la caché de pub.

Resultado: **solo 4 de los 67 traen módulo Android, y los 4 declaran
`namespace`.**

| Paquete | Versión |
| --- | --- |
| `flutter_plugin_android_lifecycle` | 2.0.19 |
| `flutter_secure_storage` | 9.2.4 |
| `image_picker_android` | 0.8.9+6 |
| `path_provider_android` | 2.2.4 |

Además lo declaran con la forma condicional
(`if (project.android.hasProperty("namespace"))`), que sirve tanto con AGP 7 como
con AGP 8, así que no hace falta tocarlos ni fijar versiones.

La aplicación tampoco tiene ese problema: `android/app/build.gradle` ya declara
`namespace "com.marcoavaria.aplicacion_mundo_otaku"`.

**Conclusión:** el costo de la migración está concentrado en los archivos Gradle
propios, no en las dependencias. Eso hace el trabajo más acotado de lo que se
temía.

**Un detalle que refuerza el orden de la cadena.** El módulo de la aplicación usa
`minSdkVersion flutter.minSdkVersion` y `targetSdkVersion flutter.targetSdkVersion`:
esos valores los pone el SDK de Flutter, no el proyecto. Con Flutter 3.16.8 no hay
forma de llegar a `targetSdk` 36 editando este archivo, porque el número sale de
otra parte. Confirma que **Flutter va primero** y que no tiene sentido intentar
atajos por el lado de Gradle.

Punto de partida medido hoy, sin cambios respecto de lo anotado antes: Gradle 7.5,
AGP 7.3.1, Kotlin 1.7.10, `compileSdkVersion` 34, Java 1.8 en `sourceCompatibility`
y `jvmTarget`.

## Verificación en un dispositivo Android 16 real (2026-09-22)

Las dos exigencias que este documento daba por pendientes —«hay que comprobarlo en
un dispositivo»— se comprobaron en un **Samsung SM-S938B con Android 16 (SDK 36)**,
pantalla de 1080 × 2340 y densidad 450. Las dos salieron bien.

### Borde a borde: no cambia nada

Android trae un interruptor de compatibilidad que permite aplicarle a una
aplicación las reglas de un `targetSdk` mayor **sin cambiarlo**. Los dos que
importan aquí, leídos del propio dispositivo, son:

| Cambio | Se activa desde |
| --- | --- |
| `ENFORCE_EDGE_TO_EDGE` (309578419) | `targetSdk` 35 |
| `DISABLE_OPT_OUT_EDGE_TO_EDGE` (377864165) | `targetSdk` 36 |

Se activaron los dos sobre el paquete y se confirmó en `dumpsys platform_compat`
que quedaban registrados (`packageOverrides={…=true}`), de modo que la aplicación
corrió bajo las reglas exactas de `targetSdk` 36:

```
adb shell am compat enable ENFORCE_EDGE_TO_EDGE <paquete>
adb shell am compat enable DISABLE_OPT_OUT_EDGE_TO_EDGE <paquete>
adb shell am force-stop <paquete> && adb shell am start -n <paquete>/.MainActivity
```

Después se recorrieron las pantallas de mayor riesgo —las que tienen contenido
pegado a un borde— y se compararon las capturas contra las del mismo recorrido con
las reglas normales:

| Pantalla | Diferencia |
| --- | --- |
| Conversación (campo de texto al fondo) | **0 píxeles** |
| Lista de chats | 0,149 %, en el centro de la pantalla |

La diferencia de la lista de chats **no es de disposición**: está en el medio de la
pantalla, sobre las miniaturas de los productos, y no en los bordes. Un cambio de
márgenes habría desplazado todo y la diferencia habría sido de casi el 100 %. Los
recortes de esa zona son indistinguibles a la vista; es ruido de decodificación de
las imágenes.

**Conclusión: el borde a borde obligatorio de Android 16 no rompe nada.** Era
esperable, porque con el cierre del rediseño las cuatro pantallas que faltaban
pasaron a usar `SafeArea`, pero ahora está medido y no supuesto.

Queda una salvedad honesta: el dispositivo estaba en **navegación por tres botones**
(`navigation_mode 0`), no por gestos. La barra de gestos es más baja, así que el
caso probado es el más exigente de los dos en altura ocupada; aun así, conviene
repetirlo en modo gestos cuando haya ocasión.

### Páginas de memoria de 16 KB: ya se cumple

Se extrajo el APK instalado y se leyeron las cabeceras de programa de cada
biblioteca nativa. **Los cuatro archivos `.so` declaran `LOAD align = 0x10000`**, es
decir 64 KB, que cubre de sobra el mínimo de 16 KB:

| Biblioteca | Alineación |
| --- | --- |
| `lib/arm64-v8a/libflutter.so` | 0x10000 |
| `lib/x86/libflutter.so` | 0x10000 |
| `lib/x86_64/libflutter.so` | 0x10000 |
| `lib/arm64-v8a/libVkLayer_khronos_validation.so` | 0x10000 |

Esto era lo que más se temía, porque una biblioteca mal alineada obliga a esperar
una versión nueva del motor y no se puede arreglar desde el proyecto. **No es el
caso**: el motor de Flutter 3.16.8 ya viene alineado.

Dos matices que conviene no perder:

- El dispositivo usa páginas de **4 KB** (`getconf PAGE_SIZE` → 4096), así que esta
  comprobación es sobre el archivo, no sobre su ejecución en un equipo de 16 KB.
  Lo que se verificó es que el binario no bloquea la migración.
- Se midió sobre un APK de **depuración**. Falta la otra mitad del requisito, que
  es de empaquetado: en una compilación de lanzamiento las bibliotecas van sin
  comprimir dentro del APK y deben quedar alineadas a 16 KB (`zipalign -P 16`).
  Eso lo resuelve la propia cadena de herramientas al actualizar AGP, así que no
  cambia el plan, pero no se ha comprobado todavía.

### Qué queda realmente por delante

Con esto, de las dos exigencias que parecían capaces de descarrilar la migración
—borde a borde y páginas de 16 KB— **ninguna la bloquea**, y de las dependencias
tampoco hay ninguna que la bloquee. El trabajo queda concentrado donde ya se había
dicho: subir Flutter primero, después AGP 8 y Gradle 8 con Java 17 y Kotlin, y al
final el `targetSdk`.
