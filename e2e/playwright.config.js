const { defineConfig } = require('@playwright/test');

const { backendDirectory, backendEnvironment } = require('./scripts/environment');
const frontendUrl = process.env.E2E_FRONTEND_URL || 'http://127.0.0.1:8080';
const backendUrl = process.env.E2E_BACKEND_URL || 'http://127.0.0.1:3001';
const browserExecutable = process.env.E2E_BROWSER_EXECUTABLE || undefined;

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1,
  timeout: 300_000,
  expect: { timeout: 20_000 },
  reporter: process.env.CI
    ? [['line'], ['html', { open: 'never' }]]
    : [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: frontendUrl,
    browserName: 'chromium',
    headless: true,
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    viewport: { width: 1280, height: 900 },
    launchOptions: browserExecutable
      ? { executablePath: browserExecutable }
      : undefined,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: [
    {
      command: 'npm run start:prod',
      cwd: backendDirectory,
      env: backendEnvironment,
      url: `${backendUrl}/api/docs`,
      reuseExistingServer: false,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
    {
      command: 'node node_modules/serve/build/main.js ../build/web --single --listen 8080',
      cwd: __dirname,
      url: frontendUrl,
      reuseExistingServer: false,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
  ],
});
