const path = require('node:path');

const frontendUrl = process.env.E2E_FRONTEND_URL || 'http://127.0.0.1:8080';
const backendUrl = process.env.E2E_BACKEND_URL || 'http://127.0.0.1:3001';
const frontendDirectory = path.resolve(__dirname, '..', '..');
const backendDirectory = path.resolve(
  process.env.MUNDO_OTAKU_BACKEND_DIR ||
    path.join(__dirname, '..', '..', '..', 'MundoOtaku-Backend-Repository', 'MundoOtaku-Backend-Repository'),
);
// El puerto en el que escucha la API se deduce de su URL, en vez de escribirse
// aparte. Antes `PORT` estaba fijo en 3001 mientras que la URL sí era
// configurable, así que apuntar `E2E_BACKEND_URL` a otro puerto dejaba a
// Playwright esperando en un sitio donde la API nunca iba a levantar.
//
// Importa en Windows: al arrancar, Hyper-V reserva rangos de puertos dinámicos,
// y si 3001 cae dentro de uno la API falla con `EACCES` aunque no haya nadie
// escuchando. Con esto, mover la suite a otro puerto es una variable de entorno
// y no hace falta tocar la configuración de red del equipo.
const backendPort = new URL(backendUrl).port || '3001';
const databasePort = process.env.E2E_DB_PORT || '5433';
const dockerProject = process.env.E2E_DOCKER_PROJECT || 'mundo-otaku-e2e';

const backendEnvironment = {
  ...process.env,
  NODE_ENV: 'test',
  DB_PASSWORD: 'postgres',
  DB_NAME: 'mundo_otaku_e2e_test',
  DB_HOST: '127.0.0.1',
  DB_PORT: databasePort,
  DB_USERNAME: 'postgres',
  DB_SYNCHRONIZE: 'false',
  PORT: backendPort,
  API_PREFIX: 'api',
  JWT_SECRET: 'browser-e2e-secret-with-at-least-32-characters',
  CORS_ORIGINS: frontendUrl,
  PUBLIC_DIR: 'public',
  PRODUCT_IMAGES_DIR: '.e2e-artifacts/products',
  // Same image driver as the published demo: bytes stored in PostgreSQL.
  IMAGE_STORAGE_DRIVER: 'postgres',
};

module.exports = {
  backendDirectory,
  backendUrl,
  backendEnvironment,
  dockerProject,
  frontendDirectory,
  frontendUrl,
  manageDatabase: process.env.E2E_MANAGE_DATABASE !== 'false',
};
