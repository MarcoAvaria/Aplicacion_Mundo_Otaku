const test = require('node:test');
const assert = require('node:assert/strict');

const {
  containsDebugReleaseSigning,
  findPlatformSecurityProblems,
  hasRequiredIosUsageDescriptions,
  isSensitiveMobileArtifact,
} = require('./check-platform-security');

test('rechaza la clave debug como firma de una compilacion release', () => {
  assert.equal(containsDebugReleaseSigning('signingConfig signingConfigs.debug'), true);
  assert.equal(containsDebugReleaseSigning('signingConfig signingConfigs.release'), false);
});

test('exige explicaciones para camara y fototeca en iOS', () => {
  const complete = [
    '<key>NSCameraUsageDescription</key>',
    '<key>NSPhotoLibraryUsageDescription</key>',
  ].join('\n');
  assert.equal(hasRequiredIosUsageDescriptions(complete), true);
  assert.equal(hasRequiredIosUsageDescriptions('<key>NSCameraUsageDescription</key>'), false);
});

test('detecta credenciales moviles y permite la plantilla documentada', () => {
  assert.equal(isSensitiveMobileArtifact('android/key.properties'), true);
  assert.equal(isSensitiveMobileArtifact('android/app/upload-keystore.jks'), true);
  assert.equal(isSensitiveMobileArtifact('ios/profile.mobileprovision'), true);
  assert.equal(isSensitiveMobileArtifact('android/key.properties.template'), false);
});

test('la configuracion versionada de todas las plataformas es segura', () => {
  assert.deepEqual(findPlatformSecurityProblems(), []);
});
