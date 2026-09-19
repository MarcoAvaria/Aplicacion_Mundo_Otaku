import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _publicApiUrl = 'https://mundo-otaku-api.onrender.com/api';
const _publicSocketUrl = 'https://mundo-otaku-api.onrender.com';
const _localApiUrl = 'http://10.0.2.2:3001/api';
const _localSocketUrl = 'http://10.0.2.2:3001';
const _localHealthUrl = 'http://127.0.0.1:3001/api/health';
const _packageName = 'com.marcoavaria.aplicacion_mundo_otaku';

Future<void> main(List<String> arguments) async {
  try {
    await _runLauncher(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Error: ${error.message}');
    exitCode = 64;
  } on StateError catch (error) {
    stderr.writeln('Error: ${error.message}');
    exitCode = 1;
  }
}

Future<void> _runLauncher(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    _printHelp();
    return;
  }

  final scriptFile = File.fromUri(Platform.script).absolute;
  final clientDirectory = scriptFile.parent.parent;
  final workspaceDirectory = clientDirectory.parent;
  final apiDirectory = Directory(_join(<String>[
    workspaceDirectory.path,
    'MundoOtaku-Backend-Repository',
    'MundoOtaku-Backend-Repository',
  ]));

  stdout.writeln('Mundo Otaku — preparación de dos emuladores Android');
  stdout.writeln('Modo: ${options.mode == _Mode.public ? 'público' : 'local'}');

  await _checkPrerequisites(options.mode, apiDirectory);
  await _checkAvds(options.emulatorNames);

  if (options.onlyCheck) {
    if (options.mode == _Mode.public) {
      await _waitForHealth(
          '$_publicApiUrl/health', const Duration(seconds: 90));
    } else {
      final docker = await _run('docker', const <String>['info']);
      if (docker.exitCode != 0) {
        throw StateError(
            'Docker Desktop está instalado, pero su motor no responde.');
      }
    }
    stdout.writeln(
        'Verificación aprobada. No se inició ningún emulador ni servicio.');
    return;
  }

  final managedProcesses = <_ManagedProcess>[];
  var cleaningUp = false;

  Future<void> cleanUp() async {
    if (cleaningUp) return;
    cleaningUp = true;
    if (managedProcesses.isEmpty) return;
    stdout.writeln('\nCerrando los procesos iniciados por este comando...');
    for (final process in managedProcesses.reversed) {
      await process.stop();
    }
    stdout.writeln(
      'Listo. Los emuladores y PostgreSQL quedan encendidos para reutilizarlos.',
    );
  }

  StreamSubscription<ProcessSignal>? sigintSubscription;
  StreamSubscription<ProcessSignal>? sigtermSubscription;
  final stopRequested = Completer<void>();

  void requestStop(ProcessSignal _) {
    if (!stopRequested.isCompleted) stopRequested.complete();
  }

  try {
    sigintSubscription = ProcessSignal.sigint.watch().listen(requestStop);
    if (!Platform.isWindows) {
      sigtermSubscription = ProcessSignal.sigterm.watch().listen(requestStop);
    }

    String apiUrl;
    String socketUrl;
    if (options.mode == _Mode.local) {
      await _prepareLocalBackend(apiDirectory, managedProcesses);
      apiUrl = _localApiUrl;
      socketUrl = _localSocketUrl;
    } else {
      stdout.writeln(
          'Despertando la API pública (Render puede tardar cerca de un minuto)...');
      await _waitForHealth(
          '$_publicApiUrl/health', const Duration(seconds: 90));
      apiUrl = _publicApiUrl;
      socketUrl = _publicSocketUrl;
    }

    stdout.writeln('Compilando un único APK debug para ambos dispositivos...');
    await _runChecked(
      'flutter',
      <String>[
        'build',
        'apk',
        '--debug',
        '--dart-define=API_URL=$apiUrl',
        '--dart-define=SOCKET_URL=$socketUrl',
      ],
      workingDirectory: clientDirectory.path,
    );
    final apkPath = _join(<String>[
      clientDirectory.path,
      'build',
      'app',
      'outputs',
      'flutter-apk',
      'app-debug.apk',
    ]);

    final devices = await _ensureEmulators(options.emulatorNames);
    stdout.writeln('Emuladores listos: ${devices.join(', ')}');

    for (var index = 0; index < devices.length; index++) {
      final label = 'Android ${index + 1}';
      final device = devices[index];
      stdout.writeln('Instalando y abriendo $label en $device...');
      await _installApk(device, apkPath);
      if (options.clearSessions) {
        stdout.writeln('Limpiando la sesión local de $device...');
        await _runChecked(
          'adb',
          <String>['-s', device, 'shell', 'pm', 'clear', _packageName],
        );
      }
      await _runChecked(
        'adb',
        <String>[
          '-s',
          device,
          'shell',
          'am',
          'force-stop',
          _packageName,
        ],
      );
      await _runChecked(
        'adb',
        <String>[
          '-s',
          device,
          'shell',
          'am',
          'start',
          '-n',
          '$_packageName/.MainActivity',
        ],
      );
      await _waitForAndroidProcess(device);
    }

    stdout.writeln('');
    stdout.writeln('Las dos aplicaciones quedaron instaladas y abiertas.');
    stdout.writeln(
        'Inicia Usuario Demo 1 en un emulador y Usuario Demo 2 en el otro.');
    if (managedProcesses.any((process) => process.label == 'API')) {
      stdout.writeln(
          'Esta terminal mantiene la API local. Presiona Ctrl+C al terminar.');
      await stopRequested.future;
    } else {
      stdout.writeln(
          'Puedes cerrar esta terminal; los emuladores seguirán abiertos.');
    }
  } finally {
    await sigintSubscription?.cancel();
    await sigtermSubscription?.cancel();
    await cleanUp();
  }
}

Future<void> _waitForAndroidProcess(String device) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    final pid = await _run(
      'adb',
      <String>['-s', device, 'shell', 'pidof', _packageName],
    );
    if (pid.exitCode == 0 && pid.stdout.toString().trim().isNotEmpty) return;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError('La aplicación no quedó abierta en $device dentro de 45 s.');
}

Future<void> _installApk(String device, String apkPath) async {
  String? lastOutput;
  for (var attempt = 1; attempt <= 3; attempt++) {
    final result = await _run(
      'adb',
      <String>['-s', device, 'install', '-r', apkPath],
    );
    lastOutput = '${result.stdout}${result.stderr}';
    if (result.exitCode == 0) return;

    if (lastOutput.contains('INSTALL_FAILED_VERIFICATION_FAILURE')) {
      stdout.writeln(
        'La verificación del AVD agotó su tiempo; se desactiva solo para instalaciones ADB de prueba.',
      );
      await _run(
        'adb',
        <String>[
          '-s',
          device,
          'shell',
          'settings',
          'put',
          'global',
          'verifier_verify_adb_installs',
          '0',
        ],
      );
      await _run(
        'adb',
        <String>[
          '-s',
          device,
          'shell',
          'settings',
          'put',
          'global',
          'package_verifier_enable',
          '0',
        ],
      );
    }
    if (attempt < 3) {
      stdout.writeln('Reintentando instalación en $device ($attempt/3)...');
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }
  throw StateError(
    'No se pudo instalar el APK en $device después de tres intentos.\n$lastOutput',
  );
}

Future<void> _checkPrerequisites(_Mode mode, Directory apiDirectory) async {
  final requiredCommands = <String>['flutter', 'adb'];
  if (mode == _Mode.local) requiredCommands.addAll(<String>['docker', 'npm']);

  for (final command in requiredCommands) {
    final result = await _run(
      Platform.isWindows ? 'where.exe' : 'which',
      <String>[command],
    );
    if (result.exitCode != 0) {
      throw StateError('No se encontró "$command" en PATH.');
    }
  }

  if (mode == _Mode.local) {
    if (!apiDirectory.existsSync()) {
      throw StateError(
          'No se encontró el repositorio backend en ${apiDirectory.path}.');
    }
    if (!File(_join(<String>[apiDirectory.path, '.env'])).existsSync()) {
      throw StateError(
        'Falta api/.env. Créalo desde .env.template antes de usar el modo local.',
      );
    }
  }
}

Future<void> _checkAvds(List<String> emulatorNames) async {
  final result = await _runChecked('flutter', const <String>['emulators']);
  for (final name in emulatorNames) {
    if (!RegExp('^${RegExp.escape(name)}\\s+•', multiLine: true)
        .hasMatch(result.stdout.toString())) {
      throw StateError(
        'No existe el AVD "$name". Créalo en Android Studio > Device Manager.',
      );
    }
  }
}

Future<void> _prepareLocalBackend(
  Directory apiDirectory,
  List<_ManagedProcess> managedProcesses,
) async {
  if (await _isHealthy(_localHealthUrl)) {
    stdout.writeln('Se reutilizará la API que ya escucha en el puerto 3001.');
    return;
  }

  stdout.writeln('Levantando PostgreSQL local sin restablecer sus datos...');
  await _runChecked(
    'docker',
    const <String>['compose', 'up', '-d', 'db'],
    workingDirectory: apiDirectory.path,
  );

  stdout.writeln('Compilando la API NestJS...');
  await _runChecked(
    'npm',
    const <String>['run', 'build'],
    workingDirectory: apiDirectory.path,
  );

  stdout.writeln('Aplicando únicamente migraciones compiladas pendientes...');
  await _runChecked(
    'npm',
    const <String>['run', 'migration:run:prod'],
    workingDirectory: apiDirectory.path,
  );

  stdout.writeln('Iniciando la API NestJS...');
  final backend = await _startManaged(
    'API',
    'node',
    const <String>['dist/main.js'],
    workingDirectory: apiDirectory.path,
  );
  managedProcesses.add(backend);

  try {
    await _waitForHealth(_localHealthUrl, const Duration(seconds: 90));
  } catch (_) {
    await backend.stop();
    rethrow;
  }
}

Future<List<String>> _ensureEmulators(List<String> emulatorNames) async {
  final resolved = <String>[];
  for (final name in emulatorNames) {
    final running = await _runningEmulatorsByAvd();
    if (!running.containsKey(name)) {
      stdout.writeln('Iniciando $name...');
      await _runChecked(
        'flutter',
        <String>['emulators', '--launch', name, '--cold'],
      );
    }
    resolved.add(await _waitForEmulator(name));
  }
  return resolved;
}

Future<String> _waitForEmulator(String name) async {
  final deadline = DateTime.now().add(const Duration(minutes: 6));
  while (DateTime.now().isBefore(deadline)) {
    final running = await _runningEmulatorsByAvd();
    final device = running[name];
    if (device != null) {
      final result = await _run(
        'adb',
        <String>['-s', device, 'shell', 'getprop', 'sys.boot_completed'],
      );
      if (result.exitCode == 0 && result.stdout.toString().trim() == '1') {
        stdout.writeln('$name terminó de arrancar como $device.');
        return device;
      }
    }
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  throw StateError(
    '$name no terminó de arrancar en seis minutos. '
    'Usa Cold Boot Now desde Device Manager.',
  );
}

Future<Map<String, String>> _runningEmulatorsByAvd() async {
  final devicesResult = await _runChecked('adb', const <String>['devices']);
  final serials = RegExp(r'^(emulator-\d+)\s+device$', multiLine: true)
      .allMatches(devicesResult.stdout.toString().replaceAll('\r', ''))
      .map((match) => match.group(1)!)
      .toList();
  final result = <String, String>{};
  for (final serial in serials) {
    final avdResult =
        await _run('adb', <String>['-s', serial, 'emu', 'avd', 'name']);
    if (avdResult.exitCode == 0) {
      final lines = avdResult.stdout
          .toString()
          .replaceAll('\r', '')
          .split('\n')
          .where((line) => line.trim().isNotEmpty && line.trim() != 'OK');
      if (lines.isNotEmpty) result[lines.first.trim()] = serial;
    }
  }
  return result;
}

Future<_ManagedProcess> _startManaged(
  String label,
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => stdout.writeln('[$label] $line'));
  process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) => stderr.writeln('[$label] $line'));
  return _ManagedProcess(label, process);
}

Future<ProcessResult> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
}

Future<ProcessResult> _runChecked(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final result = await _run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'Falló: $executable ${arguments.join(' ')}\n'
      '${result.stdout}${result.stderr}',
    );
  }
  return result;
}

Future<void> _waitForHealth(String url, Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await _isHealthy(url)) {
      stdout.writeln('API disponible: $url');
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  throw StateError(
      'La API no respondió correctamente dentro de ${timeout.inSeconds} s.');
}

Future<bool> _isHealthy(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close().timeout(const Duration(seconds: 8));
    await response.drain<void>();
    return response.statusCode == HttpStatus.ok;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

String _join(List<String> parts) => parts.join(Platform.pathSeparator);

void _printHelp() {
  stdout.writeln('''
Uso desde Aplicacion_Mundo_Otaku:

  dart run tool/pruebas_android.dart
  dart run tool/pruebas_android.dart --modo=local

Opciones:
  --modo=publico          Usa Render/Neon. Es el valor predeterminado.
  --modo=local            Levanta o reutiliza Docker, PostgreSQL y NestJS local.
  --emulador-1=NOMBRE     AVD para Usuario Demo 1 (Pixel_7_API_34 por defecto).
  --emulador-2=NOMBRE     AVD para Usuario Demo 2 (Mundo_Otaku_2 por defecto).
  --limpiar-sesiones      Borra solo los datos locales de esta app en ambos AVD.
  --solo-verificar        Comprueba requisitos sin iniciar servicios ni emuladores.
  --ayuda                 Muestra esta ayuda.

En modo local, Ctrl+C detiene la API solo si este comando la inició.
No apaga las aplicaciones, los emuladores ni PostgreSQL, y nunca restablece la base.
''');
}

enum _Mode { public, local }

class _Options {
  const _Options({
    required this.mode,
    required this.emulatorNames,
    required this.clearSessions,
    required this.onlyCheck,
    required this.showHelp,
  });

  final _Mode mode;
  final List<String> emulatorNames;
  final bool clearSessions;
  final bool onlyCheck;
  final bool showHelp;

  factory _Options.parse(List<String> arguments) {
    var mode = _Mode.public;
    var firstEmulator = 'Pixel_7_API_34';
    var secondEmulator = 'Mundo_Otaku_2';
    var clearSessions = false;
    var onlyCheck = false;
    var showHelp = false;

    for (final argument in arguments) {
      if (argument == '--modo=publico') {
        mode = _Mode.public;
      } else if (argument == '--modo=local') {
        mode = _Mode.local;
      } else if (argument.startsWith('--emulador-1=')) {
        firstEmulator = argument.substring('--emulador-1='.length);
      } else if (argument.startsWith('--emulador-2=')) {
        secondEmulator = argument.substring('--emulador-2='.length);
      } else if (argument == '--limpiar-sesiones') {
        clearSessions = true;
      } else if (argument == '--solo-verificar') {
        onlyCheck = true;
      } else if (argument == '--ayuda' || argument == '-h') {
        showHelp = true;
      } else {
        throw FormatException('Opción desconocida: $argument. Usa --ayuda.');
      }
    }

    if (firstEmulator.isEmpty || secondEmulator.isEmpty) {
      throw const FormatException(
          'Los nombres de emulador no pueden estar vacíos.');
    }
    if (firstEmulator == secondEmulator) {
      throw const FormatException('Se necesitan dos AVD distintos.');
    }

    return _Options(
      mode: mode,
      emulatorNames: <String>[firstEmulator, secondEmulator],
      clearSessions: clearSessions,
      onlyCheck: onlyCheck,
      showHelp: showHelp,
    );
  }
}

class _ManagedProcess {
  _ManagedProcess(this.label, this.process);

  final String label;
  final Process process;
  bool _stopped = false;

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    stdout.writeln('Deteniendo $label (PID ${process.pid})...');
    if (Platform.isWindows) {
      await Process.run(
        'taskkill.exe',
        <String>['/PID', '${process.pid}', '/T', '/F'],
        runInShell: false,
      );
    } else {
      process.kill(ProcessSignal.sigterm);
    }
  }
}
