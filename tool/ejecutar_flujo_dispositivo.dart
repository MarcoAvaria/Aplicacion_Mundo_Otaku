// Variante de ejecutar_flujo_android.dart para un teléfono físico conectado
// por USB, en vez de un emulador (AVD). Los siete pasos de cada flujo son
// idénticos a los de ejecutar_flujo_android.dart —así las grabaciones de
// emulador y de dispositivo real quedan comparables—, pero todo lo que
// dependía del emulador se reemplaza:
//   - el dispositivo se detecta por USB en vez de asumir "emulator-5554";
//   - no se pide abrir "Extended Controls" (no existe en un teléfono real);
//   - se verifica que la pantalla esté encendida y desbloqueada antes de tocar
//     nada, porque un teléfono real sí se bloquea solo;
//   - además del modo manual (armar la grabación con el propio teléfono), hay
//     un modo --grabar que graba con `adb shell screenrecord` y trae el video.
//
// Ningún flujo crea, edita, elimina ni envía datos reales: solo navega y lee.

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
  final explicitDevice = _value(args, '--dispositivo');
  final skipBuild = args.contains('--sin-compilar');
  final noPause = args.contains('--sin-pausa');
  final autoRecord = args.contains('--grabar');
  final recordSeconds =
      int.tryParse(_value(args, '--duracion-grabacion') ?? '') ?? 240;
  final countdownSeconds =
      int.tryParse(_value(args, '--contador') ?? '') ?? 10;
  if (flow != '01' && flow != '02' && flow != '03') {
    throw ArgumentError('Flujo desconocido: $flow. Usa --ayuda.');
  }

  _device = await _detectPhysicalDevice(explicitDevice);
  stdout.writeln('Usando dispositivo: $_device');
  await _readScreenSize();
  await _verifyScreenAwakeAndUnlocked();
  await _waitForApi();
  if (!skipBuild) await _buildAndInstall();

  await _adb(['shell', 'pm', 'clear', _package]);
  await _adb(['shell', 'am', 'start', '-n', _activity]);
  // Un teléfono real abre la app mucho más rápido que un AVD recién
  // instalado; `_waitForAppFocus` hace el sondeo real, este margen solo
  // evita consultar antes de que Android termine de despachar el intent.
  await _pause(3);
  await _waitForAppFocus();
  await _pause(2);

  String? remoteRecordingPath;
  Process? recordingProcess;
  if (autoRecord) {
    remoteRecordingPath =
        '/sdcard/mundo_otaku_flujo_${flow}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    stdout.writeln(
        'Grabando automáticamente con adb screenrecord (máx. ${recordSeconds}s)...');
    recordingProcess = await Process.start(
      'adb',
      [
        '-s',
        _device,
        'shell',
        'screenrecord',
        '--time-limit',
        '$recordSeconds',
        remoteRecordingPath,
      ],
    );
    // Un par de segundos para que el grabador arranque antes del primer tap.
    await _pause(2);
  } else {
    stdout.writeln('''
Todo está preparado en la pantalla de acceso.
Abre el centro de control del teléfono y ten a mano "Grabadora de pantalla"
(en Samsung: desliza desde arriba; si no ves el ícono, toca el lápiz de
editar accesos y agrega "Grabar pantalla"). Toca "Iniciar grabación" antes
de que termine la cuenta regresiva; el guion no espera un Enter porque quien
ejecuta este comando normalmente no es quien tiene el teléfono en la mano.

Ninguno de los flujos crea, edita, elimina ni envía datos.
''');
    if (!noPause) await _countdown(countdownSeconds);
  }

  switch (flow) {
    case '01':
      await _runFlow01();
    case '02':
      await _runFlow02();
    case '03':
      await _runFlow03();
  }

  if (autoRecord && recordingProcess != null && remoteRecordingPath != null) {
    await _stopAndPullRecording(recordingProcess, remoteRecordingPath);
  } else {
    // Un respiro sobre la última pantalla antes de avisar, para no cortar
    // la grabación justo en medio de la última transición.
    await _pause(2);
    stdout.writeln(
        '\n>>> Flujo $flow completado. Detén y guarda la grabación del teléfono ahora. <<<');
  }
}

/// Cuenta regresiva impresa en la terminal, pensada para que quien tiene el
/// teléfono en la mano (no necesariamente quien ejecuta este comando) sepa
/// exactamente cuándo tocar "Iniciar grabación". Reemplaza la espera por
/// Enter de la primera versión de este script.
Future<void> _countdown(int seconds) async {
  for (var remaining = seconds; remaining > 0; remaining--) {
    stdout.writeln('Comienza en $remaining...');
    await _pause(1);
  }
  stdout.writeln('¡Ahora! Empezando el flujo.');
}

Future<void> _runFlow01() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura de una publicación ajena');
  await _tapScaled(540, 760);
  await _pause(5);

  stdout.writeln('[3/7] Deslizamiento de fotografías');
  await _swipeScaled(880, 760, 200, 760, 900);
  await _pause(2);
  await _swipeScaled(200, 760, 880, 760, 900);
  await _pause(2);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(2);

  stdout.writeln('[4/7] Revisión de productos propios');
  await _openDrawer();
  await _tapScaled(430, 705);
  await _pause(5);

  stdout.writeln('[5/7] Revisión de chats aceptados');
  await _openDrawer();
  await _tapScaled(430, 965);
  await _pause(6);

  stdout.writeln('[6/7] Apertura de historial de chat (solo lectura)');
  await _tapScaled(540, 390);
  await _pause(9);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(2);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow02() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 2');
  await _login(2);

  stdout.writeln('[2/7] Apertura de solicitudes recibidas');
  await _openDrawer();
  await _tapScaled(430, 1220);
  await _pause(7);

  stdout.writeln('[3/7] Revisión de una propuesta pendiente');
  await _tapScaled(540, 390);
  await _pause(7);

  stdout.writeln('[4/7] Revisión visual de los productos propuestos');
  await _swipeScaled(880, 560, 200, 560, 900);
  await _pause(2);
  await _swipeScaled(880, 1220, 200, 1220, 900);
  await _pause(2);
  await _swipeScaled(540, 1800, 540, 650, 900);
  await _pause(3);

  stdout.writeln('[5/7] Regreso a solicitudes recibidas');
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(3);

  stdout.writeln('[6/7] Comprobación de solicitudes enviadas');
  await _openDrawer();
  await _tapScaled(430, 1090);
  await _pause(5);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow03() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura del buscador');
  await _tapScaled(995, 220);
  await _pause(3);

  stdout.writeln('[3/7] Búsqueda de Komi');
  await _typeSearchTerm('Komi');
  await _pause(7);

  stdout.writeln('[4/7] Apertura del producto encontrado');
  await _tapScaled(540, 350);
  await _pause(7);

  stdout.writeln('[5/7] Revisión de fotografías e información');
  await _swipeScaled(880, 760, 200, 760, 900);
  await _pause(2);
  await _swipeScaled(200, 760, 880, 760, 900);
  await _pause(2);
  await _swipeScaled(540, 1800, 540, 700, 900);
  await _pause(3);

  stdout.writeln('[6/7] Regreso al catálogo');
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(3);
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(3);

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
  // Un teléfono real con la API ya despierta autentica en pocos segundos;
  // se deja margen para variaciones normales de red, no para el "cold
  // start" de Render (ese ya se esperó aparte en _waitForApi).
  await _pause(10);
  await _verifyAuthenticated();
}

Future<void> _logout() async {
  await _openDrawer();
  await _tapScaled(430, 1350);
  await _pause(5);
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
  // Igual que en el emulador: escribir de a un carácter evita que se pierdan
  // letras cuando el teclado del sistema intercepta el texto completo.
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

/// A diferencia del script de emulador (que asume `emulator-5554` por
/// defecto), aquí se detecta el teléfono físico conectado automáticamente,
/// porque su ID de serie cambia según el equipo. Si hay más de un
/// dispositivo físico conectado, exige `--dispositivo=ID` para no adivinar.
Future<String> _detectPhysicalDevice(String? explicit) async {
  if (explicit != null) {
    final result = await Process.run('adb', ['devices']);
    if (!result.stdout
        .toString()
        .split('\n')
        .any((line) => line.startsWith('$explicit\tdevice'))) {
      throw StateError('El dispositivo $explicit no está conectado.');
    }
    return explicit;
  }

  final result = await Process.run('adb', ['devices']);
  final physicalDevices = result.stdout
      .toString()
      .split('\n')
      .skip(1)
      .map((line) => line.trim())
      .where((line) => line.endsWith('\tdevice'))
      .map((line) => line.split('\t').first)
      .where((id) => !id.startsWith('emulator-'))
      .toList();

  if (physicalDevices.isEmpty) {
    throw StateError(
      'No se detectó ningún teléfono físico por USB. Conéctalo, activa '
      '"Depuración USB" en Opciones de desarrollador y autoriza este '
      'computador en el diálogo que aparece en el teléfono, luego reintenta.',
    );
  }
  if (physicalDevices.length > 1) {
    throw StateError(
      'Hay más de un dispositivo físico conectado (${physicalDevices.join(', ')}). '
      'Especifica cuál usar con --dispositivo=ID.',
    );
  }
  return physicalDevices.single;
}

/// Comprobación best-effort: un AVD casi siempre está despierto y
/// desbloqueado, pero un teléfono real se bloquea solo. No se intenta
/// automatizar el PIN o la huella por seguridad: si parece bloqueado, se
/// pausa y se pide desbloquearlo a mano.
Future<void> _verifyScreenAwakeAndUnlocked() async {
  final power = await _adb(['shell', 'dumpsys', 'power'], quiet: true);
  final awake = power.contains('mWakefulness=Awake');
  if (!awake) {
    stdout.writeln(
        'La pantalla del teléfono parece apagada. Despiértala y desbloquéala.');
    stdin.readLineSync();
  }
}

Future<void> _readScreenSize() async {
  final output = await _adb(['shell', 'wm', 'size'], quiet: true);
  final match = RegExp(r'(\d+)x(\d+)').firstMatch(output);
  if (match == null) {
    throw StateError('No se pudo leer la resolución del teléfono.');
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
      'El inicio de sesión no creó el token local. Revisa la grabación del '
      'teléfono; el flujo se detuvo antes de navegar fuera de la app.',
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

/// Detiene la grabación automática antes de que se agote su tiempo límite
/// (si el dispositivo lo soporta), espera a que `screenrecord` cierre el
/// archivo, lo trae al computador dentro de build/ (ignorado por git) y
/// borra la copia del teléfono.
Future<void> _stopAndPullRecording(
    Process recordingProcess, String remotePath) async {
  stdout.writeln('\nDeteniendo la grabación automática...');
  // SIGINT (2) es la forma correcta de cerrar screenrecord y que el archivo
  // quede reproducible; si el teléfono no soporta pkill con señal, el
  // proceso igual termina solo al llegar a --duracion-grabacion.
  final stopped = await Process.run(
      'adb', ['-s', _device, 'shell', 'pkill', '-2', 'screenrecord']);
  if (stopped.exitCode != 0) {
    stdout.writeln(
        'No se pudo detener screenrecord manualmente; se esperará a que termine solo.');
  }
  await recordingProcess.exitCode;
  await _pause(2);

  final localDir = Directory(
      [_clientDirectory, 'build', 'grabaciones_dispositivo'].join(Platform.pathSeparator));
  if (!localDir.existsSync()) localDir.createSync(recursive: true);
  final localPath = [localDir.path, remotePath.split('/').last]
      .join(Platform.pathSeparator);

  await Process.run('adb', ['-s', _device, 'pull', remotePath, localPath]);
  await Process.run('adb', ['-s', _device, 'shell', 'rm', remotePath]);

  stdout.writeln('Grabación guardada en: $localPath');
  stdout.writeln('(esa carpeta está dentro de build/, así que no se sube a git)');
}

String? _value(List<String> args, String option) {
  final prefix = '$option=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _help() => stdout.writeln('''
Uso: dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_dispositivo.dart [opciones]

Igual que ejecutar_flujo_android.dart, pero para un teléfono conectado por
USB en vez de un emulador (AVD). Detecta el teléfono automáticamente si solo
hay uno conectado.

  --flujo=01                 Recorrido demo no destructivo.
  --flujo=02                 Revisión de solicitudes con Usuario Demo 2.
  --flujo=03                 Búsqueda y detalle de producto con Demo 1.
  --dispositivo=ID           ID de adb; si se omite, se detecta solo (falla
                              si hay más de un teléfono físico conectado).
  --sin-compilar             Reutiliza el APK normal ya instalado.
  --contador=N               Segundos de cuenta regresiva antes de empezar en
                              modo manual, para armar la grabación nativa del
                              teléfono (por defecto 10). No aplica con
                              --grabar (ese modo no necesita margen).
  --sin-pausa                No espera ni cuenta regresiva (solo para
                              verificar el script, no para grabar).
  --grabar                   Graba automáticamente con `adb shell
                              screenrecord` y trae el video a build/
                              grabaciones_dispositivo/, en vez de pedirte que
                              armes la grabación a mano en el teléfono. Nota:
                              en algunos teléfonos graba a pocos cuadros por
                              segundo (variable frame rate); si se ve poco
                              fluido, usa el modo manual con la grabadora
                              nativa en su lugar.
  --duracion-grabacion=N     Segundos máximos de grabación con --grabar
                              (por defecto 240).
  --ayuda                    Muestra esta ayuda.
''');
