const path = require('node:path');

const frontendUrl = process.env.E2E_FRONTEND_URL || 'http://127.0.0.1:8080';
const backendUrl = process.env.E2E_BACKEND_URL || 'http://127.0.0.1:3001';
const frontendDirectory = path.resolve(__dirname, '..', '..');
const backendDirectory = path.resolve(
  process.env.MUNDO_OTAKU_BACKEND_DIR ||
    path.join(__dirname, '..', '..', '..', 'MundoOtaku-Backend-Repository', 'MundoOtaku-Backend-Repository'),
);
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
  PORT: '3001',
  API_PREFIX: 'api',
  JWT_SECRET: 'browser-e2e-secret-with-at-least-32-characters',
  CORS_ORIGINS: frontendUrl,
  PUBLIC_DIR: 'public',
  PRODUCT_IMAGES_DIR: '.e2e-artifacts/products',
  IMAGE_STORAGE_DRIVER: 's3',
  S3_BUCKET: 'mundo-otaku-test',
  S3_REGION: 'us-east-1',
  S3_ENDPOINT: 'http://127.0.0.1:9000',
  S3_ACCESS_KEY_ID: 'mundo_otaku_test',
  S3_SECRET_ACCESS_KEY: 'mundo_otaku_test_secret',
  S3_FORCE_PATH_STYLE: 'true',
  S3_PREFIX: 'products',
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
