const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const repositoryDirectory = path.resolve(__dirname, '..', '..');
const scannedEntries = [
  '.github',
  'android',
  'ios',
  'lib',
  'linux',
  'macos',
  'web',
  'windows',
  path.join('e2e', 'playwright.config.js'),
];
const sourceExtensions = new Set([
  '.dart',
  '.html',
  '.js',
  '.json',
  '.yaml',
  '.yml',
]);

function containsMachinePath(content) {
  const windowsAbsolutePath = /(^|[\s'"(=])[A-Za-z]:[\\/]/m;
  const userHomePath = /(^|[\s'"(=])\/(?:Users|home)\/[\w.-]+\//m;
  return windowsAbsolutePath.test(content) || userHomePath.test(content);
}

function existingFiles(files) {
  return files.filter((file) => fs.existsSync(file));
}

function listTrackedSourceFiles() {
  const trackedFiles = execFileSync(
    'git',
    ['ls-files', '-z', '--', ...scannedEntries],
    {
      cwd: repositoryDirectory,
      encoding: 'utf8',
    },
  )
    .split('\0')
    .filter(Boolean)
    .filter((file) => sourceExtensions.has(path.extname(file)))
    .map((file) => path.join(repositoryDirectory, file));

  return existingFiles(trackedFiles);
}

function findMachinePaths() {
  return listTrackedSourceFiles()
    .filter((file) => containsMachinePath(fs.readFileSync(file, 'utf8')))
    .map((file) => path.relative(repositoryDirectory, file));
}

if (require.main === module) {
  const matches = findMachinePaths();
  if (matches.length > 0) {
    console.error(`Se encontraron rutas absolutas dependientes del equipo:\n${matches.join('\n')}`);
    process.exitCode = 1;
  } else {
    console.log('Portabilidad comprobada: no hay rutas absolutas del equipo.');
  }
}

module.exports = { containsMachinePath, existingFiles, findMachinePaths };
