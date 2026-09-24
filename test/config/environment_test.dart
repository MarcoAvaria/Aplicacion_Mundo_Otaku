// `Environment` no tenía ninguna prueba, y decide de dónde habla la aplicación.
//
// Su lógica no es trivial: valida que la URL sea absoluta, recorta la barra
// final, y **deriva** la dirección del socket a partir de la de la API cuando
// nadie la configura. Un error aquí no rompe la compilación: deja la app
// apuntando a ninguna parte, que es como se perdió una hora de esta migración
// cuando un APK quedó apuntando a `localhost` dentro del teléfono.
//
// Nota sobre el entorno de la prueba: `Environment` mira primero los valores
// compilados con `--dart-define` y solo después el archivo `.env`. En
// `flutter test` no hay `--dart-define`, así que estas pruebas ejercitan el
// camino del `.env`, que es el que usa la app de depuración.
import 'package:aplicacion_mundo_otaku/config/constants/environment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carga variables como si vinieran del `.env`, sin tocar el disco.
void _cargar(Map<String, String> variables) {
  dotenv.loadFromString(
    envString: variables.entries.map((e) => '${e.key}=${e.value}').join('\n'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(dotenv.clean);

  group('API_URL', () {
    test('sin configurar, avisa en vez de quedarse callada', () {
      _cargar({'APP_VERSION': '0.0.1'});
      expect(() => Environment.apiUrl, throwsA(isA<StateError>()));
    });

    test('vacía o solo espacios cuenta como no configurada', () {
      for (final valor in ['', '   ']) {
        _cargar({'API_URL': valor});
        expect(
          () => Environment.apiUrl,
          throwsA(isA<StateError>()),
          reason: 'el valor "$valor" debería rechazarse',
        );
      }
    });

    test('una ruta relativa se rechaza: hace falta una URL absoluta', () {
      // Es el error clásico al copiar la configuración del cliente web, donde
      // `/api` funciona porque el navegador conoce el origen. En el teléfono no
      // hay origen que completar.
      for (final valor in ['/api', 'api/v1', 'mundo-otaku.com/api']) {
        _cargar({'API_URL': valor});
        expect(
          () => Environment.apiUrl,
          throwsA(isA<StateError>()),
          reason: '"$valor" no tiene esquema ni anfitrión',
        );
      }
    });

    test('un esquema sin anfitrión también se rechaza', () {
      _cargar({'API_URL': 'http://'});
      expect(() => Environment.apiUrl, throwsA(isA<StateError>()));
    });

    test('recorta espacios alrededor', () {
      _cargar({'API_URL': '  https://mundo-otaku-api.onrender.com/api  '});
      expect(Environment.apiUrl, 'https://mundo-otaku-api.onrender.com/api');
    });

    test('quita la barra final, para no terminar pidiendo //productos', () {
      _cargar({'API_URL': 'https://mundo-otaku-api.onrender.com/api/'});
      expect(Environment.apiUrl, 'https://mundo-otaku-api.onrender.com/api');
    });

    test('quita una sola barra final, no todas', () {
      // El recorte usa una expresión regular anclada al final: si alguien
      // escribe dos barras, queda una. Se fija el comportamiento real para que
      // nadie lo confunda con un saneado general de la ruta.
      _cargar({'API_URL': 'https://ejemplo.test/api//'});
      expect(Environment.apiUrl, 'https://ejemplo.test/api/');
    });

    test('acepta direcciones locales con puerto', () {
      _cargar({'API_URL': 'http://10.0.2.2:3001/api'});
      expect(Environment.apiUrl, 'http://10.0.2.2:3001/api');
    });
  });

  group('SOCKET_URL', () {
    test('si está configurada, manda ella', () {
      _cargar({
        'API_URL': 'https://api.ejemplo.test/api',
        'SOCKET_URL': 'https://sockets.ejemplo.test',
      });
      expect(Environment.socketUrl, 'https://sockets.ejemplo.test');
    });

    test('se ignora si viene vacía o en blanco, y se deriva', () {
      for (final valor in ['', '   ']) {
        _cargar({
          'API_URL': 'https://api.ejemplo.test/api',
          'SOCKET_URL': valor,
        });
        expect(Environment.socketUrl, 'https://api.ejemplo.test');
      }
    });

    test('sin configurar, se deriva del origen de la API', () {
      // Es lo que ocurre de verdad: el `.env` del cliente no define
      // `SOCKET_URL`, y el socket vive en la raíz del mismo servidor.
      _cargar({'API_URL': 'https://mundo-otaku-api.onrender.com/api'});
      expect(Environment.socketUrl, 'https://mundo-otaku-api.onrender.com');
    });

    test('al derivar conserva el puerto', () {
      _cargar({'API_URL': 'http://127.0.0.1:3001/api'});
      expect(Environment.socketUrl, 'http://127.0.0.1:3001');
    });

    test('al derivar descarta la ruta, la consulta y el fragmento', () {
      _cargar({
        'API_URL': 'https://ejemplo.test/uno/dos/api?clave=1#ancla',
      });
      expect(Environment.socketUrl, 'https://ejemplo.test');
    });

    test('recorta espacios del valor configurado', () {
      _cargar({
        'API_URL': 'https://api.ejemplo.test/api',
        'SOCKET_URL': '  wss://sockets.ejemplo.test  ',
      });
      expect(Environment.socketUrl, 'wss://sockets.ejemplo.test');
    });

    test('si falta API_URL tampoco puede derivar, y lo dice', () {
      _cargar({'APP_VERSION': '0.0.1'});
      expect(() => Environment.socketUrl, throwsA(isA<StateError>()));
    });
  });
}
