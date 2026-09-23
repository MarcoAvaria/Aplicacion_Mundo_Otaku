/// Recorridos de demostración en Android, apuntando **por nombre accesible**.
///
/// Es la alternativa a `ejecutar_flujo_android.dart`, que sigue intacto. Aquel
/// apunta con coordenadas absolutas sobre un lienzo de referencia de 1080×2400
/// y las escala al dispositivo. Eso funciona hasta que la interfaz cambia de
/// sitio: cada rediseño obliga a volver a medir los veintitantos puntos a mano,
/// y mientras tanto los flujos tocan el vacío sin avisar. Fue lo que dejó a
/// T-021 esperando a que terminara el rediseño.
///
/// Aquí cada objetivo se busca en el árbol de accesibilidad que Flutter publica
/// a Android: se vuelca con `uiautomator dump` y se toca el centro del nodo que
/// lleva ese nombre. El recorrido se calibra solo, y como el nombre accesible es
/// el mismo que lee un lector de pantalla, un flujo que deja de encontrar su
/// objetivo está avisando de un problema real de accesibilidad, no de un píxel
/// corrido.
///
/// El otro cambio importante es que las esperas dejan de ser a ciegas. En vez de
/// `_pause(12)` con la esperanza de que la pantalla haya cargado, se espera
/// **hasta que aparezca** el nombre que marca esa pantalla. Es más rápido cuando
/// la red responde bien y no se rompe cuando responde mal.
///
/// Ninguno de los flujos crea, edita, elimina ni envía datos.
library;

import 'dart:io';

const _package = 'com.marcoavaria.aplicacion_mundo_otaku';
const _activity = '$_package/.MainActivity';
const _apiUrl = 'https://mundo-otaku-api.onrender.com/api';
const _socketUrl = 'https://mundo-otaku-api.onrender.com';

/// Dónde deja `uiautomator` el volcado dentro del dispositivo.
const _dumpPath = '/sdcard/mundo_otaku_vista.xml';

late String _device;
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
  final soloComprobar = args.contains('--solo-nombres');
  if (flow != '01' && flow != '02' && flow != '03') {
    throw ArgumentError('Flujo desconocido: $flow. Usa --ayuda.');
  }

  await _verifyDevice();

  if (soloComprobar) {
    await _listarNombres();
    return;
  }

  await _waitForApi();
  if (!skipBuild) await _buildAndInstall();

  await _adb(['shell', 'pm', 'clear', _package]);
  await _adb(['shell', 'am', 'start', '-n', _activity]);
  await _waitForAppFocus();
  // La pantalla de acceso es el punto de partida de los tres flujos. Esperarla
  // por su nombre reemplaza la pausa fija que antes hacía falta para que el AVD
  // terminara de crear su primera ventana.
  await _esperarNombre('El correo de tu cuenta', segundos: 180);

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

// ---------------------------------------------------------------------------
// Flujos
// ---------------------------------------------------------------------------

Future<void> _runFlow01() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura de una publicación ajena');
  // Las tarjetas del catálogo empiezan por el tomo; buscar "TOMO " toma la
  // primera sin depender de qué producto haya publicado nadie ese día.
  await _tocar('TOMO ');
  await _esperarNombre('Proponer intercambio');

  stdout.writeln('[3/7] Deslizamiento de fotografías');
  await _deslizarSobre('Foto 1 de 2', haciaLaIzquierda: true);
  await _esperarNombre('Foto 2 de 2');
  await _deslizarSobre('Foto 2 de 2', haciaLaIzquierda: false);
  await _esperarNombre('Foto 1 de 2');
  await _volver();

  stdout.writeln('[4/7] Revisión de productos propios');
  await _irDesdeElMenu('Mi estante');
  await _esperarNombre('productos publicados');

  stdout.writeln('[5/7] Revisión de chats aceptados');
  await _irDesdeElMenu('Chats');
  await _esperarNombre('intercambios en curso');

  stdout.writeln('[6/7] Apertura de historial de chat (solo lectura)');
  await _tocar('INTERCAMBIO EN CURSO');
  // El historial llega por el socket, así que se espera el indicador de la
  // cabecera en vez de una pausa fija.
  await _esperarNombre('Chat conectado', segundos: 60);
  await _volver();

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow02() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 2');
  await _login(2);

  stdout.writeln('[2/7] Apertura de solicitudes recibidas');
  await _irDesdeElMenu('Recibidas');
  await _esperarNombre('TE PROPONEN');

  stdout.writeln('[3/7] Revisión de una propuesta pendiente');
  await _tocar('TE PROPONEN');
  await _esperarNombre('Volver', segundos: 60);

  stdout.writeln('[4/7] Revisión visual de los productos propuestos');
  await _desplazarHaciaAbajo();
  await _pause(3);

  stdout.writeln('[5/7] Regreso a solicitudes recibidas');
  await _volver();
  await _esperarNombre('Recibidas');

  stdout.writeln('[6/7] Comprobación de solicitudes enviadas');
  await _irDesdeElMenu('Enviadas');
  await _esperarNombre('Enviadas');

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _runFlow03() async {
  stdout.writeln('[1/7] Inicio de sesión como Usuario Demo 1');
  await _login(1);

  stdout.writeln('[2/7] Apertura del buscador');
  await _tocar('Busca un tomo');
  await _pause(2);

  stdout.writeln('[3/7] Búsqueda de Komi');
  await _typeSearchTerm('Komi');
  await _esperarNombre('Komi-san', segundos: 60);

  stdout.writeln('[4/7] Apertura del producto encontrado');
  await _tocar('Komi-san');
  await _esperarNombre('Proponer intercambio', segundos: 60);

  stdout.writeln('[5/7] Revisión de fotografías e información');
  await _deslizarSobre('Foto 1 de 2', haciaLaIzquierda: true);
  await _esperarNombre('Foto 2 de 2');
  await _desplazarHaciaAbajo();
  await _pause(3);

  stdout.writeln('[6/7] Regreso al catálogo');
  await _volver();
  await _esperarNombre('Cambia y descubre', segundos: 60);

  stdout.writeln('[7/7] Cierre de sesión');
  await _logout();
}

Future<void> _login(int demoNumber) async {
  await _tocar('El correo de tu cuenta', segundos: 180);
  await _typeEmail(demoNumber);
  await _tocar('Contraseña');
  await _typePassword(demoNumber);
  // Se cierra el teclado antes de pulsar: con el teclado abierto el formulario
  // se desplaza y el botón queda en otro sitio.
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(1);
  await _tocar('Iniciar sesión');
  await _esperarNombre('Cambia y descubre', segundos: 120);
  await _verifyAuthenticated();
}

Future<void> _logout() async {
  await _irDesdeElMenu('Cerrar sesión');
  await _esperarNombre('El correo de tu cuenta', segundos: 60);
}

Future<void> _irDesdeElMenu(String entrada) async {
  await _tocar('Abrir menú');
  await _tocar(entrada);
}

Future<void> _volver() async {
  await _adb(['shell', 'input', 'keyevent', '4']);
  await _pause(2);
}

// ---------------------------------------------------------------------------
// Localización por nombre accesible
// ---------------------------------------------------------------------------

/// Un nodo del árbol de accesibilidad, reducido a lo que hace falta.
class _Nodo {
  const _Nodo(this.nombre, this.x, this.y, this.izquierda, this.derecha);

  final String nombre;
  final int x;
  final int y;
  final int izquierda;
  final int derecha;
}

/// Vuelca el árbol y devuelve el primer nodo cuyo nombre contenga [nombre].
///
/// Se mira `content-desc`, `hint` y `text`, en ese orden, porque Flutter no
/// publica el nombre siempre en el mismo sitio: los textos y botones lo ponen en
/// `content-desc`, mientras que un campo de edición lo pone en `hint`.
Future<_Nodo?> _buscarNodo(String nombre) async {
  await _adb(['shell', 'uiautomator', 'dump', _dumpPath], quiet: true);
  final xml = await _adb(['shell', 'cat', _dumpPath], quiet: true);
  final buscado = _normalizar(nombre);

  for (final coincidencia in RegExp(r'<node[^>]*>').allMatches(xml)) {
    final nodo = coincidencia.group(0)!;
    final etiqueta = ['content-desc', 'hint', 'text']
        .map((atributo) => _atributo(nodo, atributo))
        .firstWhere((valor) => valor.isNotEmpty, orElse: () => '');
    if (etiqueta.isEmpty) continue;
    if (!_normalizar(etiqueta).contains(buscado)) continue;

    final limites = RegExp(r'bounds="\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]"')
        .firstMatch(nodo);
    if (limites == null) continue;
    final x1 = int.parse(limites.group(1)!);
    final y1 = int.parse(limites.group(2)!);
    final x2 = int.parse(limites.group(3)!);
    final y2 = int.parse(limites.group(4)!);
    if (x2 <= x1 || y2 <= y1) continue;
    return _Nodo(etiqueta, (x1 + x2) ~/ 2, (y1 + y2) ~/ 2, x1, x2);
  }
  return null;
}

/// Espera a que aparezca un nodo con ese nombre y lo devuelve.
///
/// Reemplaza a las pausas fijas: termina en cuanto la pantalla está lista y
/// falla con un mensaje que dice qué se estaba buscando, en vez de seguir
/// tocando el vacío.
Future<_Nodo> _esperarNombre(String nombre, {int segundos = 40}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(limite)) {
    final nodo = await _buscarNodo(nombre);
    if (nodo != null) return nodo;
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
  throw StateError(
    'No apareció ningún elemento llamado "$nombre" en $segundos segundos. '
    'Ejecuta con --solo-nombres para ver qué hay en pantalla.',
  );
}

Future<void> _tocar(String nombre, {int segundos = 40}) async {
  final nodo = await _esperarNombre(nombre, segundos: segundos);
  stdout.writeln('    toca "${_resumir(nodo.nombre)}" en (${nodo.x}, ${nodo.y})');
  await _adb(['shell', 'input', 'tap', '${nodo.x}', '${nodo.y}']);
  await _pause(1);
}

/// Desliza horizontalmente sobre el nodo indicado, usando su ancho real.
Future<void> _deslizarSobre(String nombre,
    {required bool haciaLaIzquierda}) async {
  final nodo = await _esperarNombre(nombre);
  // Se deja un margen dentro del nodo para no arrancar justo en el borde, donde
  // Android puede interpretar el gesto como una navegación del sistema.
  final margen = ((nodo.derecha - nodo.izquierda) * 0.2).round();
  final desde = haciaLaIzquierda ? nodo.derecha - margen : nodo.izquierda + margen;
  final hasta = haciaLaIzquierda ? nodo.izquierda + margen : nodo.derecha - margen;
  await _adb([
    'shell',
    'input',
    'swipe',
    '$desde',
    '${nodo.y}',
    '$hasta',
    '${nodo.y}',
    '600',
  ]);
  await _pause(2);
}

/// Desplaza la pantalla hacia abajo, sin depender de ninguna coordenada fija.
Future<void> _desplazarHaciaAbajo() async {
  final tamano = await _adb(['shell', 'wm', 'size'], quiet: true);
  final medida = RegExp(r'(\d+)x(\d+)').firstMatch(tamano);
  if (medida == null) throw StateError('No se pudo leer la resolución.');
  final ancho = int.parse(medida.group(1)!);
  final alto = int.parse(medida.group(2)!);
  await _adb([
    'shell',
    'input',
    'swipe',
    '${ancho ~/ 2}',
    '${(alto * 0.75).round()}',
    '${ancho ~/ 2}',
    '${(alto * 0.30).round()}',
    '600',
  ]);
  await _pause(2);
}

/// Imprime todo lo que la pantalla actual expone, para diagnosticar un flujo.
Future<void> _listarNombres() async {
  await _adb(['shell', 'uiautomator', 'dump', _dumpPath], quiet: true);
  final xml = await _adb(['shell', 'cat', _dumpPath], quiet: true);
  stdout.writeln('Nombres accesibles en pantalla:\n');
  for (final coincidencia in RegExp(r'<node[^>]*>').allMatches(xml)) {
    final nodo = coincidencia.group(0)!;
    final etiqueta = ['content-desc', 'hint', 'text']
        .map((atributo) => _atributo(nodo, atributo))
        .firstWhere((valor) => valor.isNotEmpty, orElse: () => '');
    if (etiqueta.isEmpty) continue;
    final limites = RegExp(r'bounds="\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]"')
        .firstMatch(nodo);
    if (limites == null) continue;
    final x = (int.parse(limites.group(1)!) + int.parse(limites.group(3)!)) ~/ 2;
    final y = (int.parse(limites.group(2)!) + int.parse(limites.group(4)!)) ~/ 2;
    stdout.writeln('  (${x.toString().padLeft(4)}, ${y.toString().padLeft(4)})  '
        '${_resumir(etiqueta)}');
  }
}

String _atributo(String nodo, String nombre) {
  final valor =
      RegExp('$nombre="([^"]*)"').firstMatch(nodo)?.group(1) ?? '';
  return _decodificar(valor);
}

/// Deshace las entidades XML que trae el volcado.
String _decodificar(String valor) => valor
    .replaceAll('&#10;', '\n')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"');

/// Compara sin distinguir mayúsculas ni acentos.
///
/// Las etiquetas de la interfaz mezclan mayúsculas de adorno ("INTERCAMBIO EN
/// CURSO") con texto normal, y no vale la pena que un flujo se caiga por eso.
String _normalizar(String valor) {
  const con = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sin = 'aeiouunAEIOUUN';
  final minuscula = valor.toLowerCase();
  final buffer = StringBuffer();
  for (final caracter in minuscula.split('')) {
    final indice = con.indexOf(caracter);
    buffer.write(indice == -1 ? caracter : sin[indice]);
  }
  return buffer.toString();
}

String _resumir(String valor) {
  final plano = valor.replaceAll('\n', ' / ');
  return plano.length <= 60 ? plano : '${plano.substring(0, 60)}…';
}

// ---------------------------------------------------------------------------
// Entrada de texto y ciclo de vida, igual que en el flujo original
// ---------------------------------------------------------------------------

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
      'El inicio de sesión no creó el token local. Revisa la pantalla; el '
      'flujo se detuvo antes de navegar fuera de la app.',
    );
  }
}

Future<void> _waitForAppFocus() async {
  stdout.writeln('Esperando que Android entregue el foco a la app...');
  final deadline = DateTime.now().add(const Duration(seconds: 180));
  while (DateTime.now().isBefore(deadline)) {
    final output = await _adb(['shell', 'dumpsys', 'window'], quiet: true);
    final hasFocusedWindow = output.split('\n').any((line) =>
        line.contains('mCurrentFocus=') &&
        line.contains('$_package/$_package.MainActivity') &&
        !line.contains('Not Responding'));
    if (hasFocusedWindow) return;
    await _pause(3);
  }
  throw StateError('Android no entregó el foco a Mundo Otaku en 180 segundos.');
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
Uso: dart run Aplicacion_Mundo_Otaku/tool/ejecutar_flujo_por_nombres.dart [opciones]

Igual que ejecutar_flujo_android.dart, pero apuntando por nombre accesible en
vez de por coordenadas, de modo que el recorrido se calibra solo.

  --flujo=01                 Recorrido demo no destructivo.
  --flujo=02                 Revisión de solicitudes con Usuario Demo 2.
  --flujo=03                 Búsqueda y detalle de producto con Demo 1.
  --dispositivo=ID           ADB ID; por defecto emulator-5554.
  --sin-compilar             Reutiliza el APK normal ya instalado.
  --sin-pausa                No espera Enter (solo para verificar el script).
  --solo-nombres             Solo imprime lo que hay en la pantalla actual.
  --ayuda                    Muestra esta ayuda.
''');
