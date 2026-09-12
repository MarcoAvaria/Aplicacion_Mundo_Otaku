const path = require('node:path');

const frontendUrl = process.env.E2E_FRONTEND_URL || 'http://127.0.0.1:8080';
const backendDirectory = path.resolve(
  process.env.MUNDO_OTAKU_BACKEND_DIR ||
    path.join(__dirname, '..', '..', '..', 'MundoOtaku-Backend-Repository', 'MundoOtaku-Backend-Repository'),
);
const databasePort = process.env.E2E_DB_PORT || '5433';

const backendEnvironment = {
  ...process.env,
  NODE_ENV: 'test',
  DB_PASSWORD: 'postgres',
  DB_NAME: 'mundo_otaku_e2e_test',
  DB_HOST: '127.0.0.1',
  DB_PORT: databasePort,
  DB_USERNAME: 'postgres',
  DB_SYNCHRONIZE: 'false',
  PORT: '3001',
  API_PREFIX: 'api',
  JWT_SECRET: 'browser-e2e-secret-with-at-least-32-characters',
  CORS_ORIGINS: frontendUrl,
  PUBLIC_DIR: 'public',
  PRODUCT_IMAGES_DIR: '.e2e-artifacts/products',
};

module.exports = {
  backendDirectory,
  backendEnvironment,
  manageDatabase: process.env.E2E_MANAGE_DATABASE !== 'false',
};
