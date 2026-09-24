import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/socket_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una sesión nueva no reutiliza el socket ni la autenticación revocados', () {
    // Sin servidor: se inspecciona la conexión creada, antes de recibir eventos.
    // `testLoad` se retiró en flutter_dotenv 6; `loadFromString` es su
    // reemplazo y recibe el contenido en `envString`.
    dotenv.loadFromString(
        envString: 'API_URL=http://127.0.0.1:1/api\n'
            'SOCKET_URL=http://127.0.0.1:1');
    final service = SocketService.instance;
    addTearDown(service.disconnect);

    service.initialize(token: 'sesion-anterior');
    final oldSocket = service.socket;
    service.initialize(token: 'sesion-anterior');
    expect(identical(service.socket, oldSocket), isTrue);

    service.disconnect();
    service.initialize(token: 'sesion-nueva');
    expect(identical(service.socket, oldSocket), isFalse);
    expect(service.socket.auth, {'token': 'sesion-nueva'});
  });
}
