const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const {
  backendDirectory,
  backendUrl,
  backendEnvironment,
  dockerProject,
  frontendDirectory,
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

if (process.env.E2E_SKIP_FRONTEND_BUILD !== 'true') {
  run(
    process.platform === 'win32' ? 'flutter.bat' : 'flutter',
    [
      'build',
      'web',
      '--release',
      '--web-renderer',
      'html',
      `--dart-define=API_URL=${backendUrl}/api`,
      `--dart-define=SOCKET_URL=${backendUrl}`,
    ],
    { cwd: frontendDirectory },
  );
}

if (manageDatabase) {
  run('docker', [
    'compose',
    '--project-name',
    dockerProject,
    '-f',
    'docker-compose.test.yml',
    'up',
    '-d',
    '--wait',
    'test-db',
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
