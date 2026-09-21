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
  Hay que revisar que las pantallas respeten las áreas seguras: ya se usa `SafeArea`
  en las pantallas nuevas de la dirección "Tinta y Neón", pero las que todavía no se
  rediseñaron (acceso, registro, verificación de sesión y la cabecera del chat)
  están sin revisar.

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
