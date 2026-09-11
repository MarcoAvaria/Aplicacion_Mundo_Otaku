# Mundo Otaku — aplicación Flutter

Cliente multiplataforma de Mundo Otaku. Permite registrarse, explorar y publicar productos, administrar publicaciones propias, proponer intercambios y conversar en tiempo real cuando una solicitud es aceptada.

## Tecnologías

- Flutter y Dart
- Riverpod para estado y dependencias
- Dio para la API REST
- almacenamiento seguro para el JWT
- Socket.IO para chat en tiempo real
- GoRouter para navegación

## Puesta en marcha

Requisitos: Flutter instalado y la API de Mundo Otaku en ejecución.

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

## Cuentas demo

| Cuenta | Correo | Contraseña |
| --- | --- | --- |
| Usuario Demo 1 | `usuario1@mundo-otaku.demo` | `MundoOtakuDemo1!` |
| Usuario Demo 2 | `usuario2@mundo-otaku.demo` | `MundoOtakuDemo2!` |

Cada cuenta tiene cuatro productos recuperados con sus fotografías originales. Hay solicitudes de intercambio entre ambas para demostrar los estados y el chat.

## Estructura principal

El código bajo `lib/features/` se organiza por funcionalidad y separa dominio, infraestructura y presentación. Las áreas principales son autenticación, productos, intercambios y componentes compartidos.

Las rutas visuales están declaradas en `lib/config/router/app_routes.dart` y los endpoints REST en `lib/config/constants/api_endpoints.dart`. Los parámetros se codifican antes de formar una URL y la raíz del socket se configura independientemente de la API.

La sesión se guarda una sola vez en almacenamiento seguro. Al restaurarla se conecta el socket con el mismo JWT; el servidor confirma la autenticación antes de que el cliente entre en una sala. El historial llega mediante `chat-history` y los mensajes nuevos mediante `new-message`.

Las imágenes seleccionadas se leen como bytes en todas las plataformas. El cliente reconoce la firma JPEG, PNG, GIF o WebP antes de subir el archivo y usa un proveedor de imagen específico para navegador o sistema de archivos, por lo que la previsualización no depende de `dart:io` en Flutter Web.

## Verificación

```powershell
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
```

Las 12 pruebas actuales cubren formularios, detección de imágenes, rutas y endpoints, compatibilidad de mappers y comportamiento de componentes. [TESTING.md](TESTING.md) separa los casos de caja blanca y caja negra y define la siguiente suite de flujos completos. GitHub Actions ejecuta análisis, pruebas y build web en cada push y pull request. La compilación queda en `build/web/`.

## Trabajo pendiente conocido

- automatizar el recorrido completo con dos sesiones, recarga y reconexión del chat;
- completar edición de perfil y notificaciones si pasan a formar parte del alcance de la demo;
- revisar el formulario completo de publicación en navegador con cámara, galería y varias imágenes;
- actualizar dependencias por etapas después de estabilizar el recorrido principal.
