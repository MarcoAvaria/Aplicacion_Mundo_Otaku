# Estrategia de pruebas del cliente Flutter

El cliente mantiene pruebas rápidas de lógica y componentes. Se ejecutan con:

```powershell
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
flutter build apk --debug
Set-Location e2e
npm ci
npx playwright install chromium
npm run check:quality
npm test
```

## Caja blanca y pruebas unitarias

Las pruebas unitarias verifican reglas con conocimiento de la implementación:

- coincidencia y validación de contraseñas en registro;
- clasificación de imágenes locales, remotas y `blob:`;
- construcción y codificación de rutas de la aplicación y endpoints REST;
- compatibilidad del mapper de intercambios con el contrato actual y la forma antigua de relaciones.
- conservación del texto de un producto mientras el campo tiene foco y sincronización posterior de cambios externos.
- errores, reintentos y avance correcto de la paginación de productos e intercambios;
- carga y actualización fallida de una solicitud individual.
- carga fallida y reintento de un producto individual.

Los constructores `AppRoutes` y `ApiEndpoints` concentran los segmentos dinámicos y usan `Uri.encodeComponent`. La URL de la API y la del socket se leen desde `.env`; no dependen de una ruta absoluta del equipo.

La prueba Node `e2e/scripts/check-portability.test.js` inspecciona la configuración y el código ejecutable de todas las plataformas. Rechaza rutas de unidad de Windows y directorios personales de Unix; permite URL locales configurables, rutas web y rutas relativas. Android obtiene el JDK de `JAVA_HOME` o del entorno de desarrollo, y Playwright usa su Chromium salvo que se defina `E2E_BROWSER_EXECUTABLE`.

`e2e/scripts/check-platform-security.test.js` impide volver a firmar una release de Android con la clave debug, exige los permisos nativos usados por el selector de imágenes, rechaza receptores retirados y metadatos web genéricos, y detecta claves o perfiles móviles versionados por accidente.

`flutter build apk --debug` forma parte de la matriz aprobada con JDK 17. El 14 de septiembre de 2026 generó correctamente el APK debug con Temurin 17.0.13. Se conservan Gradle 7.5, AGP 7.3.1 y `compileSdkVersion 34`; la ejecución advierte que esa cadena entiende versiones antiguas del XML del SDK y que usa compatibilidad Java 8. Son advertencias de modernización, no un bloqueo del build. JDK 21 no debe usarse con esta configuración porque falla durante D8.

## Caja negra de componentes

Los widget tests renderizan componentes a través de su interfaz pública. La prueba del `CustomAppBar` comprueba que el botón Buscar solo existe cuando la pantalla entrega una acción y que un toque ejecuta esa acción.

## Recorridos completos en navegador

La suite de Playwright bajo `e2e/` levanta la API, una base PostgreSQL efímera y el build web. Cubre:

1. dos sesiones autenticadas e independientes;
2. publicación desde Chromium con dos imágenes reales y comprobación de los archivos servidos;
3. solicitud y aceptación de un intercambio;
4. mensajes en vivo por Socket.IO;
5. desconexión, conservación del mensaje no enviado y reconexión a la sala;
6. dos recargas consecutivas, recuperación del historial sin duplicados y cierre del intercambio;
7. error de red durante el login con permanencia en la pantalla y mensaje comprensible.
8. edición de una publicación propia y persistencia del cambio en la API;
9. rechazo por contenido de un archivo que suplanta una imagen PNG;
10. confirmación, eliminación y ausencia posterior de la publicación.
11. revocación del JWT durante una edición, limpieza local y retorno al acceso;
12. cancelación por quien envió y rechazo por quien recibió una solicitud pendiente.
13. error de red y reintento de las listas de productos e intercambios;
14. estados vacíos de productos propios, solicitudes enviadas, solicitudes recibidas y chats.
15. recuperación del detalle de productos ajenos sin exponer acciones de edición.

Los tests no usan la base demo conservada ni modifican sus fotografías. Cada ejecución crea usuarios, productos e intercambios propios en `mundo_otaku_e2e_test`, guarda imágenes en `.e2e-artifacts` y elimina ambos recursos al finalizar, incluso si una prueba falla. Consulta [e2e/README.md](e2e/README.md) para preparar el entorno.

## Cobertura pendiente

Los siguientes incrementos pueden añadirse sin rehacer la infraestructura:

- rechazo de permisos de cámara o galería en Android e iOS;
- perfil y notificaciones cuando esas funciones entren en el alcance de la demo.
