const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const {
  backendDirectory,
  backendEnvironment,
  dockerProject,
  manageDatabase,
} = require('./environment');

const artifactsDirectory = path.resolve(backendDirectory, '.e2e-artifacts');
const expectedArtifactsDirectory = path.join(
  path.resolve(backendDirectory),
  '.e2e-artifacts',
);
if (artifactsDirectory === expectedArtifactsDirectory) {
  fs.rmSync(artifactsDirectory, { recursive: true, force: true });
}

if (manageDatabase) {
  spawnSync(
    'docker',
    [
      'compose',
      '--project-name',
      dockerProject,
      '-f',
      'docker-compose.test.yml',
      'down',
    ],
    {
      cwd: backendDirectory,
      env: backendEnvironment,
      shell: process.platform === 'win32',
      stdio: 'inherit',
    },
  );
}
