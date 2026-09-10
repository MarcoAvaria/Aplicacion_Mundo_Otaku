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
STAGE=dev
```

Para un emulador Android suele ser necesario cambiar el host a `http://10.0.2.2:3001/api`. En un teléfono físico se usa la IP local del equipo que ejecuta la API. Si el backend se levanta en otro puerto, actualiza `API_URL`.

## Cuentas demo

| Cuenta | Correo | Contraseña |
| --- | --- | --- |
| Usuario Demo 1 | `usuario1@mundo-otaku.demo` | `MundoOtakuDemo1!` |
| Usuario Demo 2 | `usuario2@mundo-otaku.demo` | `MundoOtakuDemo2!` |

Cada cuenta tiene cuatro productos recuperados con sus fotografías originales. Hay solicitudes de intercambio entre ambas para demostrar los estados y el chat.

## Estructura principal

El código bajo `lib/features/` se organiza por funcionalidad y separa dominio, infraestructura y presentación. Las áreas principales son autenticación, productos, intercambios y componentes compartidos.

La sesión se guarda una sola vez en almacenamiento seguro. Al restaurarla se conecta el socket con el mismo JWT; el servidor confirma la autenticación antes de que el cliente entre en una sala. El historial llega mediante `chat-history` y los mensajes nuevos mediante `new-message`.

## Verificación

```powershell
flutter analyze
flutter build web --release
```

Ambos comandos pasan sin incidencias en el estado recuperado del 10 de septiembre de 2026. La compilación web queda en `build/web/`.
