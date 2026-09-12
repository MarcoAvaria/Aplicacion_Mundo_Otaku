const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const {
  backendDirectory,
  backendEnvironment,
  manageDatabase,
} = require('./environment');

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: backendDirectory,
    env: backendEnvironment,
    shell: process.platform === 'win32',
    stdio: 'inherit',
    ...options,
  });
  if (result.status !== 0) process.exit(result.status || 1);
}

if (!fs.existsSync(path.join(backendDirectory, 'package.json'))) {
  throw new Error(`Backend no encontrado en ${backendDirectory}`);
}

if (manageDatabase) {
  run('docker', [
    'compose',
    '-f',
    'docker-compose.test.yml',
    'up',
    '-d',
    '--wait',
  ]);
}

fs.mkdirSync(path.join(backendDirectory, '.e2e-artifacts', 'products'), {
  recursive: true,
});
if (process.env.E2E_SKIP_BACKEND_BUILD !== 'true') {
  run(process.platform === 'win32' ? 'npm.cmd' : 'npm', ['run', 'build']);
}
run(process.execPath, [
  path.join(backendDirectory, 'node_modules', 'typeorm', 'cli.js'),
  'migration:run',
  '-d',
  'dist/database/data-source.js',
], { shell: false });
