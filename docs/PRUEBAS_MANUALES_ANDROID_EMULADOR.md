# Pruebas manuales con dos emuladores Android

Esta guía permite revisar la estética y probar interacciones entre dos cuentas de Mundo Otaku usando emuladores (AVD). El lanzador está escrito en Dart y prepara y abre ambas aplicaciones con un solo comando.

> ¿Vas a probar en tu propio teléfono conectado por USB en vez de un emulador? Usa [PRUEBAS_MANUALES_ANDROID_DISPOSITIVO.md](PRUEBAS_MANUALES_ANDROID_DISPOSITIVO.md) en su lugar: tiene sus propios requisitos, comandos y solución de problemas, porque un teléfono real se comporta distinto a un AVD (se bloquea solo, no tiene Extended Controls, muestra la advertencia de Google Play Protect, etc.).

## La forma más sencilla: API pública

Este modo usa Render y Neon. No requiere Docker, una API local ni terminales adicionales. Como Render usa el plan gratuito, el primer arranque puede tardar cerca de un minuto.

Desde la raíz `Proyecto_Mundo_Otaku/`:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart
```

El script verifica los dos AVD, los inicia en frío si hace falta, espera cada arranque antes de abrir el siguiente, compila un único APK con las URL elegidas y lo ejecuta en ambos. En este computador los valores predeterminados son:

- `Pixel_7_API_34`: usar **Usuario Demo 1**;
- `Mundo_Otaku_2`: usar **Usuario Demo 2**.

En AVD con Google Play, la comprobación de una instalación ADB puede agotar su tiempo cuando dos emuladores consumen muchos recursos. El lanzador reintenta hasta tres veces y, únicamente si Android devuelve `INSTALL_FAILED_VERIFICATION_FAILURE`, desactiva la verificación de instalaciones ADB en esos dispositivos virtuales de prueba. No cambia la configuración del teléfono anfitrión ni de una compilación release.

| Cuenta | Correo | Contraseña |
| --- | --- | --- |
| Usuario Demo 1 | `usuario1@mundo-otaku.demo` | `MundoOtakuDemo1!` |
| Usuario Demo 2 | `usuario2@mundo-otaku.demo` | `MundoOtakuDemo2!` |

La API pública conserva los datos. Para una revisión visual puedes navegar libremente, pero evita borrar o editar los ocho productos demo. Los commits locales más recientes todavía no están publicados: el cliente que ejecuta el script sí incluye R-24 y R-34, mientras que la API pública todavía no incluye R-35 hasta que se autorice el push.

## Abrir un solo emulador e instalar la aplicación

Para una revisión rápida no necesitas abrir los dos AVD. Desde la raíz
`Proyecto_Mundo_Otaku/`, inicia el emulador principal:

```powershell
flutter emulators --launch Pixel_7_API_34
```

Espera a que Android muestre la pantalla de inicio y ejecuta este único
comando para compilar, instalar o sobrescribir la APK debug y abrir Mundo
Otaku contra la API pública:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android
```

El segundo comando sirve tanto si la aplicación no estaba instalada como si
quieres reinstalar la versión actual. Deja la terminal abierta para usar `r`
(hot reload), `R` (reinicio) o `q` (cerrar Flutter); no requiere Docker ni la
API local. Si hay un teléfono físico autorizado por ADB, el lanzador lo
prefiere automáticamente; en caso contrario usa un emulador activo (por eso,
si quieres forzar el emulador con un teléfono también conectado, indica su
identificador):

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android --dispositivo=emulator-5556
```

Puedes consultar los nombres de AVD instalados con `flutter emulators` y los
identificadores de dispositivos encendidos con `flutter devices`.

Si Android rechaza la actualización por una instalación realmente dañada o
por una firma incompatible, desinstala **solo la copia local** de Mundo Otaku
y repite el comando anterior:

```powershell
adb -s emulator-5554 uninstall com.marcoavaria.aplicacion_mundo_otaku
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android
```

La desinstalación borra la sesión y los datos locales de esa app dentro del
emulador, pero no modifica las cuentas, productos ni mensajes alojados en la
API pública.

## Grabar un caso de uso automático en un solo emulador

> **Actualización del 2026-09-22 (T-021):** el aviso anterior decía que las
> coordenadas de los flujos 01–03 correspondían a la interfaz previa al rediseño
> y que no se usaran para una toma definitiva. Ya está resuelto, pero por otro
> camino: en vez de volver a medir las coordenadas a mano existe ahora
> **`ejecutar_flujo_por_nombres.dart`**, que apunta por nombre accesible y se
> calibra solo. Los tres flujos se verificaron de punta a punta con él. Ver
> [Flujos que se calibran solos](#flujos-que-se-calibran-solos), más abajo.
>
> `ejecutar_flujo_android.dart` **sigue existiendo y sin cambios**, con sus
> coordenadas de la interfaz anterior. Se conserva como referencia; para grabar,
> usa el nuevo.

El primer flujo grabable usa **Usuario Demo 1** y la API pública. No requiere Docker, una API local ni un segundo emulador:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart
```

El script despierta Render, compila e instala la APK debug, limpia solo la sesión local y espera a que Android entregue el foco real. En este AVD ese arranque puede tardar cerca de 70 segundos, pero ocurre antes de grabar. Cuando la terminal indique `Todo está preparado`:

1. abre **Extended Controls > Record and Playback > Record**;
2. inicia la grabación;
3. vuelve a la terminal y presiona `Enter`.

El recorrido visible inicia sesión, abre una publicación ajena, desliza sus fotografías, revisa los productos propios, abre un chat aceptado en modo solo lectura y cierra sesión. No crea, edita, elimina ni envía datos. Al terminar, la terminal indica que puedes detener la grabación.

Para repetirlo sin recompilar la APK instalada:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --sin-compilar
```

Opciones y flujos disponibles:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --ayuda
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --flujo=01 --dispositivo=emulator-5554
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --flujo=02
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --flujo=03
```

Los flujos están calibrados y verificados con el perfil Pixel 7 de `1080x2400`; las coordenadas se escalan a la resolución reportada por Android, pero otro perfil puede distribuir el menú de manera diferente. `--sin-pausa` existe solo para comprobar el script y no debe usarse al grabar.

(Estos mismos tres flujos, con los mismos siete pasos cada uno, también existen para un teléfono físico en `ejecutar_flujo_dispositivo.dart`; ver [PRUEBAS_MANUALES_ANDROID_DISPOSITIVO.md](PRUEBAS_MANUALES_ANDROID_DISPOSITIVO.md).)

### Flujo 02: revisión de solicitudes con Demo 2

Este recorrido tampoco necesita otro teléfono. Inicia sesión como **Usuario Demo 2**, abre sus solicitudes recibidas, entra a la propuesta pendiente, recorre visualmente los productos ofrecido y solicitado sin pulsar **Aceptar** ni **Rechazar**, comprueba la bandeja de solicitudes enviadas y cierra sesión.

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --flujo=02
```

La demo pública verificada contiene una solicitud pendiente recibida por Demo 2 y ninguna enviada. El flujo aprovecha esos datos conservados y comprueba únicamente su presentación; no cambia el estado de la propuesta.

### Flujo 03: búsqueda y ficha de producto

Este recorrido usa **Usuario Demo 1** y tampoco necesita otra cuenta activa. Abre el buscador, consulta `Komi`, entra a `Komi-san Volumen 23`, recorre sus fotografías e información, vuelve al catálogo y cierra sesión. Es completamente de solo lectura.

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart --flujo=03
```

## Iterar la estética rápidamente con hot reload

Para ajustar colores, tipografía, espacios, bordes, tarjetas y composición, la opción más rápida es Chrome:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart
```

El comando usa la API pública, abre la app y mantiene una única terminal interactiva. Después de editar el código, presiona `r` o `R` para recompilar y reiniciar la aplicación web, o `q` para salir. La primera compilación demora más; la recarga verificada tarda una fracción de segundo. Flutter web vuelve a la ruta inicial al reiniciar, aunque conserva el almacenamiento de la sesión. No necesitas Docker ni levantar NestJS local.

Después de que una pantalla se vea bien en web, comprueba tacto, teclado y proporciones en un emulador ya iniciado:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android
```

En Android, `r` sí aplica hot reload conservando la pantalla actual y `R` reinicia la app. Esta separación permite trabajar casi como en una página web: Chrome para cambios globales muy rápidos y un solo Android para iterar una pantalla profunda sin volver a navegar. Conviene aplicar el rediseño en este orden: tema global y escalas de espaciado; componentes compartidos; una pantalla a la vez; revisión Android; y finalmente ejecución de los flujos grabables.

Los flujos automáticos usan coordenadas porque reproducen gestos ADB. Cambiar únicamente la paleta, tipografía, radios o sombras normalmente no los afecta. Mover, agrandar, reducir o reordenar botones, campos, tarjetas, menú o barra superior sí puede hacer que toquen otro lugar. Por eso deben recalibrarse una sola vez al terminar los cambios estructurales. Las pruebas Flutter basadas en widgets y las pruebas E2E web no dependen de esas coordenadas y siguen siendo la protección funcional durante el rediseño.

### Cómo automatizar chats grabando un solo emulador

El flujo 01 muestra un historial existente sin necesitar otra sesión. Para futuros flujos interactivos hay dos alternativas reproducibles:

- preparar la solicitud con un script/API antes de grabar y automatizar en pantalla la aceptación, entrada al chat y respuesta desde una cuenta;
- mientras se graba un solo emulador, hacer que un ayudante de prueba autenticado envíe el mensaje de la segunda cuenta por Socket.IO. La llegada se verá en tiempo real en el emulador grabado.

No conviene intentar grabar y automatizar dos AVD a la vez en este computador: aumenta mucho el tiempo de arranque y puede producir pausas visibles. Cada caso futuro se agregará como un valor nuevo de `--flujo`, con preparación y limpieza propias para no contaminar los datos demo.

## Modo local: cliente, API y PostgreSQL del equipo

Úsalo cuando quieras comprobar también cambios locales del backend:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --modo=local
```

El script:

1. reutiliza una API sana que ya esté escuchando en `3001`, o inicia la suya;
2. ejecuta `docker compose up -d db` sin borrar ni restaurar datos;
3. compila NestJS y aplica únicamente migraciones compiladas pendientes;
4. espera `http://127.0.0.1:3001/api/health`;
5. inicia los dos AVD y ejecuta Flutter contra `10.0.2.2:3001`.

`10.0.2.2` es la dirección con la que **un emulador Android** alcanza al equipo anfitrión; solo funciona dentro de un AVD. Un teléfono físico no puede usar esa dirección (necesitaría la IP LAN real del equipo), así que este modo local no tiene equivalente documentado para dispositivo físico: la guía de dispositivo físico solo cubre la API pública. El permiso HTTP está habilitado únicamente en el manifiesto `debug`; una compilación de distribución sigue necesitando HTTPS.

Requisitos del modo local:

- Docker Desktop encendido;
- `api/.env` creado y apuntando a la base local conservada;
- dependencias del backend instaladas con `npm ci` al menos una vez;
- puerto `3001` libre o ocupado por la propia API de Mundo Otaku.

El lanzador nunca restaura ni vacía la base. Tampoco usa las bases desechables `_test`. Si inicia la API, mantiene esa única terminal ocupada hasta que presiones `Ctrl+C`; entonces detiene solo esa API. Las aplicaciones, PostgreSQL y los emuladores quedan encendidos para poder reutilizarlos. Si reutiliza una API existente, el comando termina después de abrir ambas aplicaciones.

## ¿Cuántas terminales hacen falta?

Con el lanzador basta **una terminal**. El modo público la libera después de abrir ambas aplicaciones. El modo local muestra los registros con el prefijo `[API]` y solo mantiene la terminal ocupada cuando tuvo que iniciar el backend.

Si estás desarrollando una pantalla y necesitas enviar `r` para hot reload por separado, el flujo manual con tres terminales puede ser más cómodo:

```powershell
# Terminal 1, solo para modo local (flujo interactivo con recarga)
Set-Location MundoOtaku-Backend-Repository/MundoOtaku-Backend-Repository
docker compose up -d db
npm run start:dev

# Terminal 2
Set-Location Aplicacion_Mundo_Otaku
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3001/api --dart-define=SOCKET_URL=http://10.0.2.2:3001

# Terminal 3
Set-Location Aplicacion_Mundo_Otaku
flutter run -d emulator-5556 --dart-define=API_URL=http://10.0.2.2:3001/api --dart-define=SOCKET_URL=http://10.0.2.2:3001
```

Los identificadores `emulator-5554` y `emulator-5556` pueden cambiar; compruébalos con `flutter devices`.

## Comprobaciones y opciones útiles

Comprobar requisitos sin iniciar nada:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --solo-verificar
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --modo=local --solo-verificar
```

Si una cuenta anterior quedó guardada en los AVD, puedes borrar **solo los datos locales de Mundo Otaku** antes de ejecutar:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --limpiar-sesiones
```

Para usar otros AVD:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --emulador-1=Mi_AVD_1 --emulador-2=Mi_AVD_2
```

Consulta todas las opciones con:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/pruebas_android.dart --ayuda
```

Si solo hay un AVD, crea otro desde Android Studio: **Tools > Device Manager > Create device**. También puedes crear uno automáticamente con `flutter emulators --create --name Mundo_Otaku_2`. Dos ventanas del mismo AVD no sirven porque compartirían la misma instalación y sesión; deben ser dos dispositivos virtuales distintos.

## Recorrido manual recomendado

### Revisión visual

- Comprueba acceso, registro y mensajes de validación con teclado abierto y cerrado.
- Revisa catálogo, búsqueda, tarjetas, imágenes, textos largos, estados vacíos y carga.
- Abre un producto propio y uno ajeno; desliza entre sus fotografías.
- Revisa publicaciones propias, solicitudes enviadas, recibidas y chats.
- Cambia orientación solo como exploración: el diseño original está pensado principalmente para teléfono vertical.

### Flujo entre las dos cuentas

1. Inicia Usuario Demo 1 en el primer emulador y Usuario Demo 2 en el segundo.
2. Desde una cuenta, abre un producto de la otra y envía una solicitud de intercambio.
3. En la otra cuenta, abre solicitudes recibidas y acepta la solicitud.
4. Entra al chat desde ambos dispositivos y envía mensajes alternados.
5. Comprueba orden, ausencia de duplicados y recepción sin recargar.
6. Cierra y vuelve a abrir una aplicación; confirma que el historial reaparece.
7. Cierra sesión en una cuenta, entra nuevamente y confirma que el chat vuelve a conectarse.
8. Finaliza o cancela solo las solicitudes creadas durante esta prueba para no alterar innecesariamente la demo.

### Límites de esta revisión

- La cámara y la galería de un emulador no equivalen a probar permisos en un teléfono físico (para eso, usa la guía de dispositivo físico).
- El modo público mide además el despertar de Render; el modo local no reproduce esa latencia.
- Esta es una prueba manual exploratoria. Las regresiones repetibles siguen cubiertas por `flutter test`, las E2E de NestJS y Playwright.

## Problemas frecuentes

| Síntoma | Qué revisar |
| --- | --- |
| No aparece un AVD | `flutter emulators`; créalo o pasa su nombre con `--emulador-1/2`. |
| El AVD aparece, pero informa `Cannot find AVD system path` | Su imagen de sistema ya no está instalada. Elimina/recrea ese AVD o instala su imagen desde Android Studio > SDK Manager. |
| Android no termina de arrancar | Ábrelo desde Device Manager, usa **Cold Boot Now** y repite. |
| La instalación informa `INSTALL_FAILED_VERIFICATION_FAILURE` | El script lo corrige y reintenta automáticamente; si persiste, espera que ambos AVD queden fluidos y repite. |
| La app muestra el splash y se cierra | Recompila con el repositorio actual. Se fija `androidx.window` 1.0.0 porque la beta incluida por Flutter 3.16 falla en Android 14. |
| La API pública tarda | Espera el despertar de Render; el script concede hasta 90 segundos. |
| La API local no responde | Docker Desktop, `api/.env`, puerto `3001` y logs con prefijo `[API]`. |
| La app local dice error de red | Confirma que las URL usan `10.0.2.2`, no `localhost`. |
| Una sesión antigua aparece sola | Repite con `--limpiar-sesiones`. |
| El equipo se vuelve lento | Reduce RAM de cada AVD desde Device Manager o usa un emulador y un teléfono físico. |

## Flujos que se calibran solos

`ejecutar_flujo_por_nombres.dart` recorre los mismos tres casos, con los mismos
siete pasos, pero no usa coordenadas.

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_por_nombres.dart --flujo=01
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_por_nombres.dart --flujo=02
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_por_nombres.dart --flujo=03
```

Acepta las mismas opciones que el original (`--dispositivo`, `--sin-compilar`,
`--sin-pausa`, `--ayuda`) y añade `--solo-nombres`, que imprime todo lo que la
pantalla actual expone y sirve para averiguar por qué un paso no encuentra su
objetivo.

### Por qué existe

El flujo original apunta con coordenadas absolutas sobre un lienzo de referencia
de 1080 × 2400 y las escala a la resolución del dispositivo. Eso funciona hasta
que la interfaz cambia de sitio: cada rediseño obliga a volver a medir más de
veinte puntos a mano, y mientras tanto los pasos tocan el vacío **sin avisar**,
porque un toque en una zona sin nada no produce ningún error. Fue exactamente lo
que dejó a T-021 esperando meses a que terminara el rediseño.

El flujo nuevo busca cada objetivo en el árbol de accesibilidad que Flutter le
publica a Android: lo vuelca con `uiautomator dump` y toca el centro del nodo
que lleva ese nombre. Tres consecuencias que valen la pena:

- **Se calibra solo.** No hay ninguna coordenada escrita en el archivo. Funciona
  en cualquier resolución y sobrevive al próximo rediseño.
- **Falla diciendo qué pasó.** Si un nombre no aparece, se detiene con el nombre
  que estaba buscando, en vez de seguir tocando el vacío.
- **Vigila la accesibilidad de paso.** El nombre que usa el flujo es el mismo que
  lee un lector de pantalla. Un paso que deja de encontrar su objetivo está
  avisando de un problema real de accesibilidad, no de un píxel corrido.

Un ejemplo de lo primero, salido de la verificación: el campo de la contraseña se
resolvió en `(540, 847)` y no en los `(540, 1238)` que ocupa con el teclado
cerrado, porque al escribir el correo el formulario se desplaza hacia arriba. Una
coordenada fija habría fallado ahí; el nombre no.

### Esperas por condición en vez de pausas

El otro cambio es que las esperas dejaron de ser a ciegas. Donde el flujo
original hacía `_pause(12)` confiando en que la pantalla hubiera cargado, el
nuevo espera **hasta que aparezca** el nombre que identifica esa pantalla. Es más
rápido cuando la red responde bien y no se rompe cuando responde mal, que es la
misma lección que dejó T-026 en los recorridos Playwright.

### Verificación

Los tres flujos se corrieron de punta a punta el 2026-09-22 sobre un **teléfono
real**, un Samsung SM-S938B con Android 16 y pantalla de 1080 × 2340 —es decir,
una resolución distinta de la de referencia—, y los tres terminaron en cierre de
sesión sin un solo ajuste manual.
