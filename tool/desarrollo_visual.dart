import 'dart:io';

const _apiUrl = 'https://mundo-otaku-api.onrender.com/api';
const _socketUrl = 'https://mundo-otaku-api.onrender.com';

Future<void> main(List<String> args) async {
  if (args.contains('--ayuda') || args.contains('-h')) {
    _help();
    return;
  }

  final platform = _value(args, '--plataforma') ?? 'web';
  if (platform != 'web' && platform != 'android') {
    throw ArgumentError('Plataforma desconocida: $platform. Usa --ayuda.');
  }
  final device = platform == 'web'
      ? 'chrome'
      : _value(args, '--dispositivo') ?? await _preferredAndroidDevice();

  final clientDirectory = File.fromUri(Platform.script).parent.parent.path;
  await _verifyFlutter();
  if (platform == 'android') await _verifyAndroidDevice(device);
  await _waitForApi();

  stdout.writeln(platform == 'web'
      ? '''
Iniciando Mundo Otaku en Chrome para iteración visual rápida.

Mientras Flutter esté ejecutándose:
  r o R  recompila y reinicia la aplicación web
  q      termina esta sesión
'''
      : '''
Iniciando Mundo Otaku en $device con hot reload.

Mientras Flutter esté ejecutándose:
  r  aplica los cambios conservando la pantalla actual
  R  reinicia la aplicación
  q  termina esta sesión
''');

  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final process = await Process.start(
    flutter,
    [
      'run',
      '-d',
      device,
      '--dart-define=API_URL=$_apiUrl',
      '--dart-define=SOCKET_URL=$_socketUrl',
    ],
    workingDirectory: clientDirectory,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
}

Future<void> _verifyFlutter() async {
  final command = Platform.isWindows ? 'where.exe' : 'which';
  final result = await Process.run(command, ['flutter']);
  if (result.exitCode != 0) {
    throw StateError('Flutter no está disponible en PATH.');
  }
}

Future<String> _preferredAndroidDevice() async {
  final result = await Process.run('adb', ['devices']);
  final devices = <String>[];
  for (final line in result.stdout.toString().split('\n')) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1] == 'device') devices.add(parts[0]);
  }
  if (devices.isEmpty) {
    throw StateError(
      'No hay un Android autorizado. Conecta un teléfono con depuración USB '
      'o inicia un emulador.',
    );
  }
  return devices.firstWhere(
    (device) => !device.startsWith('emulator-'),
    orElse: () => devices.first,
  );
}

Future<void> _verifyAndroidDevice(String device) async {
  final result = await Process.run('adb', ['devices']);
  final connected = result.stdout
      .toString()
      .split('\n')
      .any((line) => line.startsWith('$device\tdevice'));
  if (!connected) {
    throw StateError(
      'El dispositivo $device no está conectado. Inícialo desde Android '
      'Studio > Device Manager y vuelve a ejecutar el comando.',
    );
  }
}

Future<void> _waitForApi() async {
  stdout.writeln('Despertando la API pública...');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  try {
    while (DateTime.now().isBefore(deadline)) {
      try {
        final request = await client.getUrl(Uri.parse('$_apiUrl/health'));
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode == HttpStatus.ok) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  } finally {
    client.close(force: true);
  }
  throw StateError('La API pública no respondió dentro de 90 segundos.');
}

String? _value(List<String> args, String option) {
  final prefix = '$option=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _help() => stdout.writeln('''
Uso desde la raíz Proyecto_Mundo_Otaku:

  dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart
  dart run Aplicacion_Mundo_Otaku/tool/desarrollo_visual.dart --plataforma=android

Opciones:
  --plataforma=web          Chrome con hot reload; valor predeterminado.
  --plataforma=android      Un teléfono autorizado o emulador Android activo.
  --dispositivo=ID          ADB ID específico. Sin esta opción se prefiere un
                            teléfono físico y luego cualquier emulador activo.
  --ayuda                   Muestra esta ayuda.

Ambos modos usan la API pública. No requieren Docker ni otra terminal.
''');
