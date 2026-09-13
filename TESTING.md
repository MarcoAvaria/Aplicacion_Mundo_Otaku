# Estrategia de pruebas del cliente Flutter

El cliente mantiene pruebas rápidas de lógica y componentes. Se ejecutan con:

```powershell
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
Set-Location e2e
npm ci
npx playwright install chromium
npm test
```

## Caja blanca y pruebas unitarias

Las pruebas unitarias verifican reglas con conocimiento de la implementación:

- coincidencia y validación de contraseñas en registro;
- clasificación de imágenes locales, remotas y `blob:`;
- construcción y codificación de rutas de la aplicación y endpoints REST;
- compatibilidad del mapper de intercambios con el contrato actual y la forma antigua de relaciones.
- conservación del texto de un producto mientras el campo tiene foco y sincronización posterior de cambios externos.

Los constructores `AppRoutes` y `ApiEndpoints` concentran los segmentos dinámicos y usan `Uri.encodeComponent`. La URL de la API y la del socket se leen desde `.env`; no dependen de una ruta absoluta del equipo.

## Caja negra de componentes

Los widget tests renderizan componentes a través de su interfaz pública. La prueba del `CustomAppBar` comprueba que el botón Buscar solo existe cuando la pantalla entrega una acción y que un toque ejecuta esa acción.

## Recorridos completos en navegador

La suite de Playwright bajo `e2e/` levanta la API, una base PostgreSQL efímera y el build web. Cubre:

1. dos sesiones autenticadas e independientes;
2. publicación desde Chromium con dos imágenes reales y comprobación de los archivos servidos;
3. solicitud y aceptación de un intercambio;
4. mensajes en vivo por Socket.IO;
5. desconexión, conservación del mensaje no enviado y reconexión a la sala;
6. recuperación del historial tras recargar y cierre del intercambio;
7. error de red durante el login con permanencia en la pantalla y mensaje comprensible.
8. edición de una publicación propia y persistencia del cambio en la API;
9. rechazo por contenido de un archivo que suplanta una imagen PNG;
10. confirmación, eliminación y ausencia posterior de la publicación.
11. revocación del JWT durante una edición, limpieza local y retorno al acceso;
12. cancelación por quien envió y rechazo por quien recibió una solicitud pendiente.

Los tests no usan la base demo conservada ni modifican sus fotografías. Cada ejecución crea usuarios, productos e intercambios propios en `mundo_otaku_e2e_test`, guarda imágenes en `.e2e-artifacts` y elimina ambos recursos al finalizar, incluso si una prueba falla. Consulta [e2e/README.md](e2e/README.md) para preparar el entorno.

## Cobertura pendiente

Los siguientes incrementos pueden añadirse sin rehacer la infraestructura:

- rechazo de permisos de cámara o galería en Android e iOS;
- perfil, notificaciones y estados vacíos cuando esas funciones entren en el alcance de la demo.
