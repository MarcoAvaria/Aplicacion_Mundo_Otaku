# Estrategia de pruebas del cliente Flutter

El cliente mantiene pruebas rápidas de lógica y componentes. Se ejecutan con:

```powershell
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
```

## Caja blanca y pruebas unitarias

Las pruebas unitarias verifican reglas con conocimiento de la implementación:

- coincidencia y validación de contraseñas en registro;
- clasificación de imágenes locales, remotas y `blob:`;
- construcción y codificación de rutas de la aplicación y endpoints REST;
- compatibilidad del mapper de intercambios con el contrato actual y la forma antigua de relaciones.

Los constructores `AppRoutes` y `ApiEndpoints` concentran los segmentos dinámicos y usan `Uri.encodeComponent`. La URL de la API y la del socket se leen desde `.env`; no dependen de una ruta absoluta del equipo.

## Caja negra de componentes

Los widget tests renderizan componentes a través de su interfaz pública. La prueba del `CustomAppBar` comprueba que el botón Buscar solo existe cuando la pantalla entrega una acción y que un toque ejecuta esa acción.

## Próximos flujos de integración

Una suite futura bajo `integration_test/` debe ejecutar la aplicación contra la base efímera del backend y cubrir:

1. registro o login de Usuario Demo 1 y Usuario Demo 2 en dos sesiones;
2. catálogo, publicación con imágenes y edición del producto propio;
3. solicitud, aceptación y visualización sincronizada del intercambio;
4. envío, persistencia y recuperación de mensajes tras una recarga;
5. completar o cancelar el intercambio;
6. expiración de sesión, caída de red, archivo inválido, permisos y estados vacíos.

Los tests no deben usar la base demo conservada ni modificar sus fotografías. Cada ejecución debe crear datos propios en una base terminada en `_test` y eliminar el entorno al finalizar.
