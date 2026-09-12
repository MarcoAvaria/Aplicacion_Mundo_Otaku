# Pruebas completas en navegador

Esta suite usa Playwright y Chromium para verificar el cliente Flutter contra la API NestJS, PostgreSQL y almacenamiento compatible con S3 reales. No usa la base ni los productos demo.

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

Construye el cliente con las direcciones del entorno E2E:

```powershell
Set-Location ..
flutter build web --release --web-renderer html `
  --dart-define=API_URL=http://127.0.0.1:3001/api `
  --dart-define=SOCKET_URL=http://127.0.0.1:3001
```

Ejecuta todos los recorridos:

```powershell
Set-Location e2e
npm test
```

`npm test` prepara el backend, crea PostgreSQL temporal en el puerto 5433 y MinIO temporal en el 9000, crea el bucket, ejecuta migraciones, inicia API y web, corre las pruebas y limpia todos los contenedores y objetos. Para depurar visualmente puede usarse `npm run test:headed`; los rastros, capturas y videos de fallos quedan en `test-results/`.

Variables opcionales:

| Variable | Propósito | Valor predeterminado |
| --- | --- | --- |
| `MUNDO_OTAKU_BACKEND_DIR` | Ruta absoluta al backend | repositorio vecino |
| `E2E_SKIP_BACKEND_BUILD` | Omite `npm run build` si `dist/` ya está actualizado | `false` |
| `E2E_MANAGE_DATABASE` | Usa una base ya administrada al definir `false` | `true` |
| `E2E_DB_PORT` | Puerto PostgreSQL del entorno de prueba | `5433` |
| `E2E_FRONTEND_URL` | Origen web permitido por CORS | `http://127.0.0.1:8080` |
| `E2E_BACKEND_URL` | Raíz pública de la API para Playwright | `http://127.0.0.1:3001` |
