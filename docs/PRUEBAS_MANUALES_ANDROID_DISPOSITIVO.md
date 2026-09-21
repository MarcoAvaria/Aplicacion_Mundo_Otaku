# Pruebas manuales en un teléfono Android físico (USB)

Esta guía cubre revisar Mundo Otaku en tu propio teléfono conectado por cable, en vez de un emulador (AVD). Úsala cuando quieras: ver la app con la resolución, densidad de píxeles y rendimiento reales; probar los permisos reales de cámara y galería (un emulador no los reproduce de forma confiable); o grabar un recorrido automático en hardware real.

> ¿Prefieres un emulador, o no tienes un teléfono a mano? Usa [PRUEBAS_MANUALES_ANDROID_EMULADOR.md](PRUEBAS_MANUALES_ANDROID_EMULADOR.md) en su lugar.

Todo lo de esta guía usa la **API pública** (Render + Neon). No existe un modo local equivalente para dispositivo físico: `10.0.2.2` (la dirección que usa el modo local con emuladores) solo funciona dentro de un AVD, no desde un teléfono real.

## 1. Preparar el teléfono una sola vez

1. Abre **Ajustes > Acerca del teléfono** (o **Información del software**) y toca 7 veces seguidas **Número de compilación** hasta que aparezca "Ya eres desarrollador".
2. Entra a **Ajustes > Opciones de desarrollador** y activa **Depuración USB**.
3. Conecta el teléfono al computador con un cable USB que transmita datos (no solo carga).
4. Si el teléfono muestra un selector de modo USB, elige **Transferencia de archivos (MTP)**; algunos equipos lo dejan en "Solo carga" por defecto y ADB no ve el dispositivo en ese modo.
5. Aparecerá en el teléfono un diálogo **"¿Permitir depuración USB?"** con la huella RSA de este computador. Acéptalo (marca "Permitir siempre desde este equipo" si es tu computador habitual).

Esta preparación solo se repite si cambias de computador o revocas las autorizaciones USB desde **Opciones de desarrollador > Revocar autorizaciones de depuración USB**.

## 2. Verificar la conexión

Desde la raíz `Proyecto_Mundo_Otaku/`:

```powershell
adb devices -l
flutter devices
```

Debes ver tu teléfono listado con el estado `device` (no `unauthorized` ni `offline`). Si dice `unauthorized`, revisa el diálogo de autorización en la pantalla del teléfono. Si no aparece nada, prueba otro cable o puerto USB.

Ejemplo real verificado en este proyecto (Samsung Galaxy S24 Ultra):

```
List of devices attached
R5GL416C8ST            device product:pa3qxxx model:SM_S938B device:pa3q transport_id:1
```

Ese identificador (`R5GL416C8ST` en este caso, será distinto en tu teléfono) es el que usan los comandos `--dispositivo=ID` más abajo, aunque casi nunca necesitas copiarlo a mano: los scripts de este proyecto lo detectan solo cuando hay un único teléfono conectado.

## 3. Instalar y abrir la app en modo interactivo (hot reload)

Para instalar la app y dejar una sesión de desarrollo con recarga en caliente:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android
```

Si hay un teléfono físico autorizado por ADB, este lanzador lo prefiere automáticamente sobre cualquier emulador. Si tienes varios dispositivos conectados (por ejemplo un AVD además del teléfono) y quieres forzar el teléfono, indica su identificador:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android --dispositivo=R5GL416C8ST
```

La primera instalación puede mostrar una advertencia de **Google Play Protect** porque es una APK debug instalada por cable, no desde Play Store. Selecciona **Más detalles > Instalar de todas formas**. Las ejecuciones siguientes conservan la conexión interactiva: `r` aplica hot reload conservando la pantalla actual, `R` reinicia la app y `q` cierra Flutter. El teléfono usa las URL HTTPS públicas, por lo que no necesita `10.0.2.2`, Docker ni una API local.

Si Android rechaza la actualización por una instalación dañada o una firma incompatible, desinstala **solo la copia local** de Mundo Otaku de tu teléfono (esto no toca la API ni los datos de Render/Neon) y repite el comando anterior:

```powershell
adb -s R5GL416C8ST uninstall com.marcoavaria.aplicacion_mundo_otaku
dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android
```

## 4. Ejecutar un caso de uso automático (flujos grabables)

`ejecutar_flujo_dispositivo.dart` es el equivalente para teléfono físico de `ejecutar_flujo_android.dart` (el de emulador): reproduce exactamente los mismos tres flujos, con los mismos siete pasos cada uno, escalando las coordenadas a la resolución real de tu pantalla. Lo que cambia frente a la versión de emulador:

- detecta tu teléfono por USB automáticamente (no asume `emulator-5554`); si hay más de un dispositivo físico conectado, te pide que indiques cuál con `--dispositivo=ID`;
- verifica que la pantalla esté encendida antes de empezar — un teléfono real se bloquea solo, un AVD casi nunca; si la detecta apagada, pausa y te pide desbloquearla a mano (por seguridad, el script nunca intenta escribir tu PIN o usar tu huella);
- no pide abrir "Extended Controls" (eso no existe en un teléfono real): puedes armar la grabación con la grabadora de pantalla nativa del teléfono, **o** dejar que el propio script grabe automáticamente con `adb shell screenrecord` (ver más abajo).

> **Mismo aviso que en el emulador:** los flujos 01–03 siguen describiendo casos válidos, pero sus coordenadas corresponden a la interfaz anterior al rediseño editorial en curso. No los uses para una toma definitiva hasta que se recalibren tras aprobar la nueva dirección visual.

### Comando básico

Con la app ya instalada (por ejemplo, porque acabas de hacer el paso 3), desde la raíz `Proyecto_Mundo_Otaku/`:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01 --sin-compilar
```

Si prefieres que el script compile e instale la APK debug primero (por ejemplo, si no la tienes instalada o quieres asegurarte de que corre el código más reciente), omite `--sin-compilar`:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01
```

El script: detecta el teléfono, lee su resolución, comprueba que la pantalla esté despierta, despierta la API pública (Render puede tardar hasta un minuto si estaba dormida), instala si corresponde, limpia solo la sesión local (`pm clear`, no toca la API), abre Mundo Otaku y espera a que Android le entregue el foco real antes de tocar nada.

### Los tres flujos disponibles

| Flujo | Cuenta | Qué recorre |
| --- | --- | --- |
| `01` (por defecto) | Usuario Demo 1 | Abre una publicación ajena, desliza sus fotografías, revisa productos propios, abre un chat aceptado en modo solo lectura y cierra sesión. |
| `02` | Usuario Demo 2 | Abre solicitudes recibidas, entra a la propuesta pendiente, recorre visualmente los productos ofrecido y solicitado (sin Aceptar/Rechazar), comprueba solicitudes enviadas y cierra sesión. |
| `03` | Usuario Demo 1 | Busca `Komi`, abre `Komi-san Volumen 23`, recorre sus fotografías e información, vuelve al catálogo y cierra sesión. |

Los tres son de solo lectura: no crean, editan, eliminan ni envían datos reales.

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=02 --sin-compilar
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=03 --sin-compilar
```

### Grabar el recorrido

Hay dos formas de grabar. **La recomendada es la Opción A**, porque se verificó que produce un video notoriamente más fluido.

**Opción A — grabadora nativa del teléfono (recomendada, manual):** si no pasas `--grabar`, el script imprime instrucciones y luego una **cuenta regresiva** (10 segundos por defecto) en vez de esperar `Enter` — porque quien ejecuta el comando normalmente no es quien tiene el teléfono en la mano:

1. antes de correr el comando, ten a mano el panel rápido del teléfono con "Grabadora de pantalla" visible (en Samsung: desliza desde arriba; si no aparece el ícono, toca el lápiz de editar accesos y agrégalo una vez);
2. corre el comando; en cuanto la terminal empiece a imprimir `Comienza en 10...`, `9...`, `8...`, toca **Iniciar grabación** en el teléfono (el diálogo de confirmación de Android también hay que aceptarlo con un toque);
3. al terminar el flujo, la terminal imprime en mayúsculas que ya puedes detener y guardar la grabación.

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01 --sin-compilar
```

Si 10 segundos te quedan justos (por ejemplo, si el panel rápido con el ícono de grabar está a varios deslizamientos de distancia), alárgalo:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01 --sin-compilar --contador=20
```

**Opción B — grabación automática con `adb screenrecord`:** agrega `--grabar` y el script graba por su cuenta, sin pedirte nada en el teléfono ni necesitar que estés presente:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01 --sin-compilar --grabar
```

> **Limitación verificada:** en el Samsung Galaxy S24 Ultra usado para probar este script, un video grabado con `adb shell screenrecord` dio un framerate promedio de **~7 fps** (medido con `ffprobe`), notoriamente menos fluido que la grabadora nativa. `screenrecord` codifica con tasa de cuadros variable y solo cuando detecta cambios en pantalla, así que en teléfonos o versiones de Android donde eso se comporta peor, el video se ve entrecortado. El archivo en sí queda íntegro y reproducible (no corrupto), simplemente menos fluido. Úsala cuando nadie pueda estar presente para tocar "Iniciar grabación", no como primera opción.

El video de la Opción B queda en `Aplicacion_Mundo_Otaku/build/grabaciones_dispositivo/` (esa carpeta está dentro de `build/`, que ya está en `.gitignore`, así que nunca se sube por accidente). Por defecto graba hasta 240 segundos como máximo, pero se corta antes apenas el flujo termina (usa `pkill -2` para cerrar `screenrecord` a tiempo; en algunos teléfonos ese comando reporta error aunque igual corta la grabación cerca del final, así que no te preocupes si ves ese aviso). Si necesitas más margen:

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01 --sin-compilar --grabar --duracion-grabacion=300
```

### Todas las opciones

```powershell
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --ayuda
```

| Opción | Qué hace |
| --- | --- |
| `--flujo=01` \| `02` \| `03` | Elige el recorrido. Por defecto `01`. |
| `--dispositivo=ID` | Fuerza un ID de ADB concreto. Si lo omites, se detecta solo (falla con un mensaje claro si hay 0 o más de 1 teléfono físico conectado). |
| `--sin-compilar` | Reutiliza el APK ya instalado, sin recompilar. Úsalo si la app ya está instalada y abierta. |
| `--contador=N` | Segundos de cuenta regresiva antes de empezar en modo manual (Opción A), para armar la grabación nativa. Por defecto 10. No aplica con `--grabar`. |
| `--sin-pausa` | No espera ni cuenta regresiva. Pensado para verificar el script, no para grabar con la Opción A (te quedarías sin margen para armar la grabación). |
| `--grabar` | Graba automáticamente con `adb shell screenrecord` y trae el video (ver Opción B). |
| `--duracion-grabacion=N` | Segundos máximos de grabación con `--grabar` (por defecto 240). |
| `--ayuda` | Muestra esta ayuda. |

### Ejemplo completo, de cero

Con el teléfono recién conectado y autorizado, sin la app instalada todavía, grabando con la Opción A (recomendada):

```powershell
Set-Location "D:\Escritorio del otro disco\CosasUe\Proyecto_Mundo_Otaku"
adb devices -l
dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart --flujo=01
```

Ese único comando compila, instala, despierta la API pública, cuenta regresiva de 10 segundos para que actives la grabadora nativa, ejecuta el flujo 01 completo y te avisa cuándo detener y guardar el video desde el teléfono.

## 5. Diferencias clave frente al emulador

- **No hay modo local.** Un teléfono físico no puede usar `10.0.2.2`; toda esta guía trabaja siempre contra la API pública en Render/Neon.
- **La pantalla se bloquea sola.** Antes de correr un flujo, asegúrate de que el teléfono esté desbloqueado (o el script pausará pidiéndotelo).
- **Google Play Protect** avisa en la primera instalación por cable; es normal, no es un problema de la app.
- **Permisos reales de cámara y galería.** A diferencia de un emulador, aquí sí puedes verificar de verdad los diálogos de permiso al publicar un producto con fotos.
- **Desinstalar afecta solo ese teléfono.** `adb -s <ID> uninstall com.marcoavaria.aplicacion_mundo_otaku` borra la sesión y los datos locales de ese dispositivo únicamente; nunca toca la API pública ni la base demo.

## Recorrido manual recomendado (un solo dispositivo)

Con un único teléfono no puedes tener dos cuentas abiertas a la vez como con dos emuladores. Dos formas de cubrir eso:

- **Revisión visual con una sola cuenta:** repite el checklist de la guía de emulador (acceso, catálogo, búsqueda, productos propio/ajeno, publicaciones, solicitudes, chats) usando cualquiera de las dos cuentas demo.
- **Flujo entre las dos cuentas, combinando teléfono + emulador:** abre un AVD además del teléfono (`flutter emulators --launch Pixel_7_API_34`), inicia una cuenta en cada uno con `desarrollo_visual.dart --plataforma=android --dispositivo=ID` apuntando a cada dispositivo por separado, y sigue el mismo recorrido de dos cuentas descrito en la guía de emulador.

### Límites de esta revisión

- Es una prueba manual exploratoria, igual que en emulador. Las regresiones repetibles siguen cubiertas por `flutter test`, las E2E de NestJS y Playwright.
- El despertar de Render (hasta un minuto en frío) también aplica aquí.

## Problemas frecuentes

| Síntoma | Qué revisar |
| --- | --- |
| El teléfono no aparece en `adb devices` | Cambia de cable/puerto USB; confirma que el modo USB sea "Transferencia de archivos", no "Solo carga". |
| Aparece como `unauthorized` | Revisa el diálogo "¿Permitir depuración USB?" en la pantalla del teléfono y acéptalo. |
| Aparece como `offline` | Desconecta y vuelve a conectar el cable; si persiste, reinicia `adb` con `adb kill-server` seguido de `adb devices`. |
| El script dice "Hay más de un dispositivo físico conectado" | Pasa `--dispositivo=ID` con el que quieras usar; consulta los ID con `adb devices -l`. |
| El script dice "La pantalla del teléfono parece apagada" | Despiértala y desbloquéala manualmente, luego presiona `Enter` en la terminal. |
| Aviso de Google Play Protect al instalar | Normal en una APK debug instalada por cable. **Más detalles > Instalar de todas formas**. |
| "El inicio de sesión no creó el token local" | El flujo se detuvo antes de completar el login; revisa la grabación para ver en qué paso falló (coordenadas desactualizadas tras un cambio de interfaz, teclado tapando un campo, etc.). |
| El video de `--grabar` no aparece o dura menos de lo esperado | Revisa `Aplicacion_Mundo_Otaku/build/grabaciones_dispositivo/`; si `pkill` no está disponible en tu teléfono, `screenrecord` igual se detiene solo al llegar a `--duracion-grabacion`. |
| La API pública tarda | Espera el despertar de Render; el script concede hasta 90 segundos. |
| La app muestra el splash y se cierra | Recompila con el repositorio actual (sin `--sin-compilar`). |
