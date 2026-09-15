# Pruebas completas en navegador

Esta suite usa Playwright y Chromium para verificar el cliente Flutter contra la API NestJS y PostgreSQL reales, con las imágenes guardadas en la base (`IMAGE_STORAGE_DRIVER=postgres`), igual que la demo publicada. No usa la base ni los productos demo.

## Requisitos

- Flutter 3.16.8;
- Node.js 20 o posterior;
- Docker Desktop en ejecución;
- el repositorio del backend en la ubicación vecina predeterminada o indicada por `MUNDO_OTAKU_BACKEND_DIR`.

Instala las dependencias una vez:

```powershell
Set-Location e2e
npm ci
npx playwright install chromium
```

Ejecuta todos los recorridos:

```powershell
Set-Location e2e
npm test
```

`npm test` construye el cliente con las direcciones del entorno E2E, prepara el backend, crea PostgreSQL temporal en el puerto 5433, ejecuta migraciones, inicia API y web, corre las pruebas y limpia los contenedores. Los servicios usan un proyecto Docker propio y no se mezclan con la base demo local. Para depurar visualmente puede usarse `npm run test:headed`; los rastros, capturas y videos de fallos quedan en `test-results/`.

Los recorridos cubren dos sesiones, publicación con varias imágenes, intercambio y chat por Socket.IO, pérdida de red, reconexiones consecutivas e historial sin duplicados, error de red durante el acceso, las listas y los detalles, reintentos, estados vacíos, edición de una publicación propia, ausencia de edición en productos ajenos, rechazo de contenido que no corresponde a una imagen, eliminación confirmada, revocación de una sesión activa, cancelación y rechazo de solicitudes.

Variables opcionales:

| Variable | Propósito | Valor predeterminado |
| --- | --- | --- |
| `MUNDO_OTAKU_BACKEND_DIR` | Ruta absoluta al backend | repositorio vecino |
| `E2E_SKIP_FRONTEND_BUILD` | Omite el build web si `build/web` ya está actualizado | `false` |
| `E2E_SKIP_BACKEND_BUILD` | Omite `npm run build` si `dist/` ya está actualizado | `false` |
| `E2E_MANAGE_DATABASE` | Usa una base ya administrada al definir `false` | `true` |
| `E2E_DOCKER_PROJECT` | Nombre aislado del proyecto Docker Compose | `mundo-otaku-e2e` |
| `E2E_DB_PORT` | Puerto PostgreSQL del entorno de prueba | `5433` |
| `E2E_FRONTEND_URL` | Origen web permitido por CORS | `http://127.0.0.1:8080` |
| `E2E_BACKEND_URL` | Raíz pública de la API para Playwright | `http://127.0.0.1:3001` |
| `E2E_BROWSER_EXECUTABLE` | Ejecutable alternativo de Chromium/Chrome, si se desea usar uno externo | Chromium instalado por Playwright |

El proyecto no fija rutas absolutas del equipo. Android obtiene el JDK de `JAVA_HOME` o del entorno de desarrollo. `npm run check:portability` revisa el código ejecutable y la configuración de todas las plataformas, y también se ejecuta automáticamente antes de los recorridos. Las direcciones locales de la tabla son valores predeterminados aislados y pueden reemplazarse mediante variables de entorno.
