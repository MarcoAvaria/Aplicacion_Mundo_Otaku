const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const repositoryDirectory = path.resolve(__dirname, '..', '..');

function containsDebugReleaseSigning(content) {
  return /signingConfig\s+signingConfigs\.debug/.test(content);
}

function hasRequiredIosUsageDescriptions(content) {
  return [
    'NSCameraUsageDescription',
    'NSPhotoLibraryUsageDescription',
  ].every((key) => content.includes(`<key>${key}</key>`));
}

function isSensitiveMobileArtifact(file) {
  const normalized = file.replaceAll('\\', '/').toLowerCase();
  if (normalized.endsWith('/key.properties.template')) return false;
  return /(^|\/)(key\.properties|[^/]+\.(jks|keystore|p12|mobileprovision|pem))$/.test(normalized);
}

function listTrackedSensitiveArtifacts() {
  return execFileSync('git', ['ls-files', '-z'], {
    cwd: repositoryDirectory,
    encoding: 'utf8',
  })
    .split('\0')
    .filter(Boolean)
    .filter(isSensitiveMobileArtifact);
}

function findPlatformSecurityProblems() {
  const read = (file) => fs.readFileSync(path.join(repositoryDirectory, file), 'utf8');
  const gradle = read('android/app/build.gradle');
  const androidManifest = read('android/app/src/main/AndroidManifest.xml');
  const iosPlist = read('ios/Runner/Info.plist');
  const webIndex = read('web/index.html');
  const webManifest = read('web/manifest.json');
  const problems = [];

  if (containsDebugReleaseSigning(gradle)) {
    problems.push('Android release usa la clave de depuracion');
  }
  if (!androidManifest.includes('android.permission.INTERNET')) {
    problems.push('Android main no declara el permiso INTERNET');
  }
  if (androidManifest.includes('flutter_local_notifications')) {
    problems.push('Android conserva receptores de notificaciones retirados');
  }
  if (!hasRequiredIosUsageDescriptions(iosPlist)) {
    problems.push('iOS no explica el uso de camara y fototeca');
  }
  if (
    webIndex.includes('A new Flutter project') ||
    webManifest.includes('aplicacion_mundo_otaku')
  ) {
    problems.push('Web conserva metadatos genericos de Flutter');
  }

  for (const file of listTrackedSensitiveArtifacts()) {
    problems.push(`Artefacto movil sensible versionado: ${file}`);
  }
  return problems;
}

if (require.main === module) {
  const problems = findPlatformSecurityProblems();
  if (problems.length > 0) {
    console.error(`Configuracion de plataforma insegura:\n${problems.join('\n')}`);
    process.exitCode = 1;
  } else {
    console.log('Configuracion de plataforma comprobada.');
  }
}

module.exports = {
  containsDebugReleaseSigning,
  findPlatformSecurityProblems,
  hasRequiredIosUsageDescriptions,
  isSensitiveMobileArtifact,
};
