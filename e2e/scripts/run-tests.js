const { spawnSync } = require('node:child_process');
const path = require('node:path');

const e2eDirectory = path.resolve(__dirname, '..');
const node = process.execPath;

function run(script, args = []) {
  return spawnSync(node, [script, ...args], {
    cwd: e2eDirectory,
    env: process.env,
    stdio: 'inherit',
    shell: false,
  });
}

let exitCode = 1;

try {
  const preparation = run(path.join(__dirname, 'prepare-environment.js'));
  if (preparation.error) throw preparation.error;
  if (preparation.status !== 0) {
    exitCode = preparation.status ?? 1;
  } else {
    const playwright = run(
      path.join(e2eDirectory, 'node_modules', '@playwright', 'test', 'cli.js'),
      ['test', ...process.argv.slice(2)],
    );
    if (playwright.error) throw playwright.error;
    exitCode = playwright.status ?? 1;
  }
} catch (error) {
  console.error(error);
  exitCode = 1;
} finally {
  const cleanup = run(path.join(__dirname, 'cleanup-environment.js'));
  if (cleanup.error) console.error(cleanup.error);
  if (cleanup.status !== 0 && exitCode === 0) exitCode = cleanup.status ?? 1;
}

process.exit(exitCode);
