const test = require('node:test');
const assert = require('node:assert/strict');

const { containsMachinePath, findMachinePaths } = require('./check-portability');

test('detecta rutas absolutas propias de Windows y directorios de usuario Unix', () => {
  assert.equal(containsMachinePath("const browser = 'C:\\\\Program Files\\\\Chrome';"), true);
  assert.equal(containsMachinePath("const backend = '/home/developer/backend';"), true);
  assert.equal(containsMachinePath("const design = '/Users/developer/project';"), true);
});

test('permite rutas relativas, URL configurables y rutas internas de servidor', () => {
  assert.equal(containsMachinePath("const backend = '../backend';"), false);
  assert.equal(containsMachinePath("const api = process.env.API_URL || 'http://127.0.0.1:3001';"), false);
  assert.equal(containsMachinePath("app.get('/home/profile');"), false);
});

test('el código ejecutable y la configuración del cliente no fijan rutas del equipo', () => {
  assert.deepEqual(findMachinePaths(), []);
});
