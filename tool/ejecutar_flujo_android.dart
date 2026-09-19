import 'dart:io';

const _package = 'com.marcoavaria.aplicacion_mundo_otaku';
const _activity = '$_package/.MainActivity';
const _apiUrl = 'https://mundo-otaku-api.onrender.com/api';
const _socketUrl = 'https://mundo-otaku-api.onrender.com';

late String _device;
late int _width;
late int _height;
late String _clientDirectory;

Future<void> main(List<String> args) async {
  if (args.contains('--ayuda') || args.contains('-h')) {
    _help();
    return;
  }

  _clientDirectory = File.fromUri(Platform.script).parent.parent.absolute.path;
  final flow = _value(args, '--flujo') ?? '01';
  _device = _value(args, '--dispositivo') ?? 'emulator-5554';
  final skipBuild = args.contains('--sin-compilar');
  final noPause = args.contains('--sin-pausa');
  if (flow != '01' && flow != '02' && flow != '03') {
    throw ArgumentError('Flujo desconocido: $flow. Usa --ayuda.');
  }

  await _verifyDevice();
  await _readScreenSize();
  await _waitForApi();
  if (!skipBuild) await _buildAndInstall();

  await _adb(['shell', 'pm', 'clear', _package]);
  await _adb(['shell', 'am', 'start', '-n', _activity]);
  // Este AVD tarda cerca de un minuto en crear su primera ventana tras instalar.
  // Esperar antes de consultar evita confundir la ventana anterior con la nueva.
  await _pause(70);
  await _waitForAppFocus();
  await _pause(3);

  stdout.writeln('''
Todo está preparado en la pantalla de acceso.
1. Abre Extended Controls > Record and Playback > Record.
2. Inicia la grabación.
3. Vuelve aquí y presiona Enter.

Ninguno de los flujos crea, edita, elimina ni envía datos.
''');
  if (!noPause) stdin.readLineSync();

  switch (flow) {
    case '01':
      await _runFlow01();
    case '02':
      await _runFlow02();
    case '03':
      await _runFlow03();
  }
  stdout.writeln(
      '\nFlujo $flow completado. Ya puedes detener y guardar la grabación.');
}

Future<void> _runFlow01() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura de una publicación ajena');
  await _tapScaled(540, 760);
  await _pause(8);

  stdout.writeln('[3/7] Deslizamiento de fotografías');
  await _swipeScaled(880, 760, 200, 760, 900);
  await _pause(2);
  await _swipeScaled(200, 760, 880, 760, 900);
  await _pause(2);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(4);

  stdout.writeln('[4/7] Revisión de productos propios');
  await _openDrawer();
  await _tapScaled(430, 705);
  await _pause(8);

  stdout.writeln('[5/7] Revisión de chats aceptados');
  await _openDrawer();
  await _tapScaled(430, 965);
  await _pause(10);

  stdout.writeln('[6/7] Apertura de historial de chat (solo lectura)');
  await _tapScaled(540, 390);
  await _pause(15);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(4);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow02() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 2');
  await _login(2);

  stdout.writeln('[2/7] Apertura de solicitudes recibidas');
  await _openDrawer();
  await _tapScaled(430, 1220);
  await _pause(12);

  stdout.writeln('[3/7] Revisión de una propuesta pendiente');
  await _tapScaled(540, 390);
  await _pause(12);

  stdout.writeln('[4/7] Revisión visual de los productos propuestos');
  await _swipeScaled(880, 560, 200, 560, 900);
  await _pause(2);
  await _swipeScaled(880, 1220, 200, 1220, 900);
  await _pause(2);
  await _swipeScaled(540, 1800, 540, 650, 900);
  await _pause(5);

  stdout.writeln('[5/7] Regreso a solicitudes recibidas');
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(6);

  stdout.writeln('[6/7] Comprobación de solicitudes enviadas');
  await _openDrawer();
  await _tapScaled(430, 1090);
  await _pause(10);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow03() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura del buscador');
  await _tapScaled(995, 220);
  await _pause(4);

  stdout.writeln('[3/7] Búsqueda de Komi');
  await _typeSearchTerm('Komi');
  await _pause(12);

  stdout.writeln('[4/7] Apertura del producto encontrado');
  await _tapScaled(540, 350);
  await _pause(12);

  stdout.writeln('[5/7] Revisión de fotografías e información');
  await _swipeScaled(880, 760, 200, 760, 900);
  await _pause(2);
  await _swipeScaled(200, 760, 880, 760, 900);
  await _pause(2);
  await _swipeScaled(540, 1800, 540, 700, 900);
  await _pause(5);

  stdout.writeln('[6/7] Regreso al catálogo');
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(5);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(5);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _login(int demoNumber) async {
  await _tapScaled(540, 600);
  await _typeEmail(demoNumber);
  await _tapScaled(540, 780);
  await _typePassword(demoNumber);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(1);
  await _tapScaled(540, 1050);
  await _pause(25);
  await _verifyAuthenticated();
}

Future<void> _logout() async {
  await _openDrawer();
  await _tapScaled(430, 1350);
  await _pause(10);
}

Future<void> _buildAndInstall() async {
  stdout.writeln(
      'Compilando la app normal de depuración (puede tardar varios minutos)...');
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final build = await Process.start(
    flutter,
    [
      'build',
      'apk',
      '--debug',
      '--dart-define=API_URL=$_apiUrl',
      '--dart-define=SOCKET_URL=$_socketUrl',
    ],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _clientDirectory,
  );
  if (await build.exitCode != 0) {
    throw StateError('Falló la compilación Flutter.');
  }
  final apk = [
    _clientDirectory,
    'build',
    'app',
    'outputs',
    'flutter-apk',
    'app-debug.apk',
  ].join(Platform.pathSeparator);
  await _adb(['install', '-r', apk]);
}

Future<void> _typeEmail(int demoNumber) async {
  await _adb(['shell', 'input', 'text', 'usuario$demoNumber']);
  await _pause(1);
  await _adb(['shell', 'input', 'keyevent', '77']); // @
  await _pause(1);
  await _adb(['shell', 'input', 'text', 'mundo-otaku']);
  await _pause(1);
  await _adb(['shell', 'input', 'keyevent', '56']); // .
  await _pause(1);
  await _adb(['shell', 'input', 'text', 'demo']);
  await _pause(2);
}

Future<void> _typePassword(int demoNumber) async {
  await _adb(['shell', 'input', 'text', 'MundoOtakuDemo$demoNumber\\!']);
  await _pause(2);
}

Future<void> _typeSearchTerm(String term) async {
  // Algunos AVD pierden letras si ADB escribe toda la consulta de una vez.
  for (final character in term.split('')) {
    await _adb(['shell', 'input', 'text', character]);
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
}

Future<void> _openDrawer() async {
  await _tapScaled(72, 220);
  await _pause(2);
}

Future<void> _tapScaled(int x, int y) => _adb([
      'shell',
      'input',
      'tap',
      '${x * _width ~/ 1080}',
      '${y * _height ~/ 2400}'
    ]);

Future<void> _swipeScaled(int x1, int y1, int x2, int y2, int milliseconds) =>
    _adb([
      'shell',
      'input',
      'swipe',
      '${x1 * _width ~/ 1080}',
      '${y1 * _height ~/ 2400}',
      '${x2 * _width ~/ 1080}',
      '${y2 * _height ~/ 2400}',
      '$milliseconds'
    ]);

Future<void> _pause([int seconds = 3]) =>
    Future<void>.delayed(Duration(seconds: seconds));

Future<void> _verifyDevice() async {
  final result = await Process.run('adb', ['devices']);
  if (!result.stdout
      .toString()
      .split('\n')
      .any((line) => line.startsWith('$_device\tdevice'))) {
    throw StateError('El dispositivo $_device no está conectado.');
  }
}

Future<void> _readScreenSize() async {
  final output = await _adb(['shell', 'wm', 'size'], quiet: true);
  final match = RegExp(r'(\d+)x(\d+)').firstMatch(output);
  if (match == null) {
    throw StateError('No se pudo leer la resolución del emulador.');
  }
  _width = int.parse(match.group(1)!);
  _height = int.parse(match.group(2)!);
}

Future<void> _verifyAuthenticated() async {
  final result = await Process.run('adb', [
    '-s',
    _device,
    'shell',
    'run-as',
    _package,
    'ls',
    'shared_prefs',
  ]);
  final files = result.stdout.toString();
  if (result.exitCode != 0 || !files.contains('FlutterSecureStorage')) {
    throw StateError(
      'El inicio de sesión no creó el token local. Revisa la captura del '
      'emulador; el flujo se detuvo antes de navegar fuera de la app.',
    );
  }
}

Future<void> _waitForAppFocus() async {
  stdout.writeln('Esperando que Android entregue el foco a la app...');
  final deadline = DateTime.now().add(const Duration(seconds: 120));
  while (DateTime.now().isBefore(deadline)) {
    final output = await _adb(['shell', 'dumpsys', 'window'], quiet: true);
    final hasFocusedWindow = output.split('\n').any((line) =>
        line.contains('mCurrentFocus=') &&
        line.contains('$_package/$_package.MainActivity') &&
        !line.contains('Not Responding'));
    if (hasFocusedWindow) {
      return;
    }
    await _pause(3);
  }
  throw StateError('Android no entregó el foco a Mundo Otaku en 120 segundos.');
}

Future<String> _adb(List<String> args, {bool quiet = false}) async {
  final result = await Process.run('adb', ['-s', _device, ...args]);
  if (result.exitCode != 0) {
    throw ProcessException(
        'adb', args, result.stderr.toString(), result.exitCode);
  }
  if (!quiet && result.stdout.toString().trim().isNotEmpty) {
    stdout.write(result.stdout);
  }
  return result.stdout.toString();
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
        if (response.statusCode == 200) return;
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
Uso: dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_android.dart [opciones]

  --flujo=01                 Recorrido demo no destructivo.
  --flujo=02                 Revisión de solicitudes con Usuario Demo 2.
  --flujo=03                 Búsqueda y detalle de producto con Demo 1.
  --dispositivo=ID           ADB ID; por defecto emulator-5554.
  --sin-compilar             Reutiliza el APK normal ya instalado.
  --sin-pausa                No espera Enter (solo para verificar el script).
  --ayuda                    Muestra esta ayuda.
''');
