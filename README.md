# Mundo Otaku — aplicación Flutter

Cliente multiplataforma de Mundo Otaku. Permite registrarse, explorar y publicar productos, administrar publicaciones propias, proponer intercambios y conversar en tiempo real cuando una solicitud es aceptada.

Proyecto de título individual de Marco Avaria. Demo pública: **https://mundo-otaku-web.onrender.com**. API: https://mundo-otaku-api.onrender.com/api; documentación: https://mundo-otaku-api.onrender.com/api/docs.

La publicación usa Render Free para Flutter Web/Nginx y NestJS, y Neon Free (PostgreSQL 16) para datos y fotografías. Los servicios gratuitos pueden tardar cerca de un minuto en despertar. El 15 de septiembre de 2026 se verificó la persistencia de un producto y sus fotos tras reiniciar la API.

## Tecnologías

- Flutter 3.16.8 y Dart 3.2.5
- Riverpod para estado y dependencias
- Dio para la API REST
- almacenamiento seguro para el JWT
- Socket.IO para chat en tiempo real
- GoRouter para navegación

## Puesta en marcha

Requisitos: Flutter instalado y la API de Mundo Otaku en ejecución. Para compilar Android con la versión actual de Gradle se requiere JDK 17 configurado mediante `JAVA_HOME` o la opción de JDK del IDE; el repositorio no guarda la ubicación local del JDK.

```powershell
Copy-Item .env.template .env
flutter pub get
flutter run -d chrome --web-port 8080
```

`.env` contiene únicamente configuración pública del cliente:

```env
APP_VERSION=0.0.1
API_URL=http://localhost:3001/api
SOCKET_URL=http://localhost:3001
STAGE=dev
```

Para un emulador Android suele ser necesario cambiar el host a `http://10.0.2.2:3001/api`. En un teléfono físico se usa la IP local del equipo que ejecuta la API. Si el backend se levanta en otro puerto, actualiza `API_URL` y `SOCKET_URL`.

Para revisar la aplicación y probar intercambios/chat con dos cuentas, el proyecto incluye un lanzador Dart que abre dos emuladores desde una sola terminal. Puede usar la API pública sin Docker o levantar el entorno local completo. Consulta [Pruebas manuales con dos emuladores Android](docs/PRUEBAS_MANUALES_ANDROID.md).

Las URL HTTP son exclusivamente para desarrollo local. Una distribución debe configurar `API_URL` y `SOCKET_URL` con HTTPS/WSS y certificados válidos.

### Firma de Android release

El repositorio no contiene claves ni usa la firma debug para una distribución. Para generar un APK o App Bundle firmado, copia `android/key.properties.template` como `android/key.properties`, crea tu keystore fuera del control de versiones y completa las cuatro propiedades. `storeFile` se resuelve desde `android/app/`; por ejemplo, `../upload-keystore.jks` apunta a `android/upload-keystore.jks`. Sin esa configuración, Gradle puede compilar un artefacto release sin firma, pero no uno distribuible.

Los certificados, perfiles de aprovisionamiento y archivos `key.properties` reales están excluidos por `.gitignore`. Las descripciones de cámara y fototeca de iOS, el permiso de Internet de Android y los metadatos web están declarados en sus archivos nativos.

### Despliegue web de portafolio

`render.yaml` y el `Dockerfile` publican Flutter Web detrás de Nginx con fallback para rutas SPA, comprobación `/healthz` y cabeceras defensivas. El build se detiene si `API_URL` o `SOCKET_URL` no usan HTTPS. Al crear el Blueprint de Render se deben introducir valores públicos como:

```text
API_URL=https://mundo-otaku-api.onrender.com/api
SOCKET_URL=https://mundo-otaku-api.onrender.com
```

La API y la base en Neon (datos y fotos) se preparan primero siguiendo `docs/DEPLOYMENT_RENDER_NEON.md` en el repositorio backend. El Blueprint del cliente usa el plan gratuito de Render en la región `virginia`. Las URL se incorporan al JavaScript durante la compilación y no deben contener secretos.

## Cuentas demo

| Cuenta         | Correo                      | Contraseña         |
| -------------- | --------------------------- | ------------------ |
| Usuario Demo 1 | `usuario1@mundo-otaku.demo` | `MundoOtakuDemo1!` |
| Usuario Demo 2 | `usuario2@mundo-otaku.demo` | `MundoOtakuDemo2!` |

Cada cuenta tiene cuatro productos recuperados con sus fotografías originales. Hay solicitudes de intercambio entre ambas para demostrar los estados y el chat.

## Estructura principal

El código bajo `lib/features/` se organiza por funcionalidad y separa dominio, infraestructura y presentación. Las áreas principales son autenticación, productos, intercambios y componentes compartidos.

Las rutas visuales están declaradas en `lib/config/router/app_routes.dart` y los endpoints REST en `lib/config/constants/api_endpoints.dart`. Los parámetros se codifican antes de formar una URL y la raíz del socket se configura independientemente de la API.

La sesión se guarda una sola vez en almacenamiento seguro. Al restaurarla se conecta el socket con el mismo JWT; el servidor confirma la autenticación antes de que el cliente entre en una sala. El historial llega mediante `chat-history` y los mensajes nuevos mediante `new-message`.

Las imágenes seleccionadas se leen como bytes en todas las plataformas. El cliente reconoce la firma JPEG, PNG, GIF o WebP antes de subir el archivo y usa un proveedor de imagen específico para navegador o sistema de archivos, por lo que la previsualización no depende de `dart:io` en Flutter Web.

## Verificación

Entrega nocturna local del 17 de septiembre de 2026: **23 pruebas Flutter, 8 controles Node y 6 recorridos Playwright aprobados**, análisis sin hallazgos y builds web release/Android debug correctos. R-24 permite arrastrar las fotos con ratón; R-34 renueva la conexión al cambiar de sesión y verifica recargas, logout/login y reinicio real de la API local. [Evidencia de R-34](docs/VERIFICACION_R34.md). Estos commits aún no están publicados y no tienen una nueva CI remota.

Línea base publicada: 20 pruebas Flutter, 8 controles Node y 6 recorridos Playwright con PostgreSQL efímero y el driver de imágenes `postgres`. GitHub Actions aprobó el commit `fa1858e` (run `35030412956`); consulta de estado repetida el 17 de septiembre de 2026. El backend asociado tiene 40 unitarias y 26 E2E aprobadas. Estos resultados corresponden a esa versión, no a pruebas nuevas de funciones futuras.

```powershell
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
flutter build apk --debug
Set-Location e2e
npm run check:quality
```

Las pruebas rápidas cubren formularios, detección de imágenes, rutas y endpoints, compatibilidad de mappers y comportamiento de componentes. La suite de Playwright ejecuta además el flujo completo con dos usuarios, dos imágenes, intercambio, chat, pérdida de red, reconexiones consecutivas e historial sin duplicados; también comprueba edición, rechazo de archivos inválidos, eliminación de publicaciones, revocación de sesión, cancelación y rechazo de solicitudes. [TESTING.md](TESTING.md) describe la estrategia y [e2e/README.md](e2e/README.md) explica su ejecución. GitHub Actions verifica análisis, pruebas, build web y recorridos de navegador en cada push y pull request.

Las únicas dependencias Node del repositorio pertenecen a Playwright y se administran dentro de `e2e/`. La aplicación usa exclusivamente las dependencias Dart declaradas en `pubspec.yaml`.

La compilación Android debug está aprobada con JDK 17. El 14 de septiembre de 2026 se repitió `flutter build apk --debug` con Temurin 17.0.13 y se generó correctamente `app-debug.apk`. La cadena permanece en Gradle 7.5, Android Gradle Plugin 7.3.1 y `compileSdkVersion 34`; por su antigüedad emite advertencias de compatibilidad con el SDK actual y debe modernizarse por separado antes de preparar una distribución. JDK 21 no es compatible con esta configuración y produjo fallos de D8.

El lockfile se actualizó dentro de las restricciones actuales y se verificó con análisis, pruebas, build web y el recorrido Playwright completo. Firebase y sus flujos incompletos se retiraron; las migraciones mayores pendientes de Riverpod, GoRouter y Socket.IO se mantienen como entregas independientes.

## Trabajo pendiente conocido

- completar edición de perfil y notificaciones si pasan a formar parte del alcance de la demo;
- comprobar en dispositivos reales la concesión y denegación de permisos de cámara y fototeca;
- migrar dependencias mayores por grupos pequeños y repetir la matriz después de cada grupo.
