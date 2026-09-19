// Control de ciclo de vida exclusivo de Playwright. Nunca controla un PID ajeno.
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { once } = require('node:events');
const { backendDirectory, backendEnvironment } = require('./environment');

const controlFile = path.join(backendDirectory, '.e2e-artifacts', 'api-command.json');
const stateFile = path.join(backendDirectory, '.e2e-artifacts', 'api-state.json');

if (backendEnvironment.NODE_ENV !== 'test' ||
    !backendEnvironment.DB_NAME.endsWith('_test') ||
    backendEnvironment.DB_HOST !== '127.0.0.1' ||
    backendEnvironment.DATABASE_URL) {
  throw new Error('El ciclo de vida solo puede controlar la API con base local de pruebas.');
}

let child;
let busy = false;
let lastCommand;
let closing = false;

function start() {
  child = spawn(process.execPath, ['dist/main.js'], {
    cwd: backendDirectory,
    env: backendEnvironment,
    stdio: 'inherit',
    windowsHide: true,
  });
  child.on('error', (error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

async function stop() {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  const exited = once(child, 'exit');
  child.kill('SIGKILL');
  await exited;
  child = undefined;
}

fs.mkdirSync(path.dirname(controlFile), { recursive: true });
fs.writeFileSync(controlFile, '{}');
start();
fs.writeFileSync(stateFile, JSON.stringify({ pid: child.pid }));

const timer = setInterval(async () => {
  if (busy || closing) return;
  let command;
  try { command = JSON.parse(fs.readFileSync(controlFile, 'utf8')); }
  catch { return; }
  if (!command.id || command.id === lastCommand) return;
  busy = true;
  try {
    if (command.action === 'stop') await stop();
    else if (command.action === 'start' && !child) start();
    else throw new Error('Comando de ciclo de vida inválido');
    lastCommand = command.id;
    fs.writeFileSync(stateFile, JSON.stringify({ id: command.id, pid: child?.pid ?? null }));
  } catch (error) {
    fs.writeFileSync(stateFile, JSON.stringify({ id: command.id, error: error.message }));
    lastCommand = command.id;
  } finally {
    busy = false;
  }
}, 100);

async function shutdown() {
  closing = true;
  clearInterval(timer);
  await stop();
  process.exit();
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
