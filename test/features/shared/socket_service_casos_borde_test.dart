// Casos borde del servicio de socket, que es un objeto único con ciclo de vida.
//
// `socket_session_test.dart` sigue intacto: cubre el caso que originó T-013
// —que una sesión nueva no reutilice un socket con el JWT revocado—. Este
// archivo cubre lo demás: qué pasa antes de inicializar, qué pasa después de
// desconectar, y qué devuelve el envío cuando no se puede enviar.
//
// Lo que **no** se puede probar aquí, y conviene saberlo: sin un servidor no
// llega el evento `authenticated`, así que `isConnected` nunca pasa a `true` y
// el camino feliz del envío no se ejercita. Eso lo cubren los recorridos
// Playwright, que sí levantan una API real. Aquí se vigilan los caminos
// infelices, que son los que se rompen en silencio.
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/socket_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

const _chat = 'intercambio-1';
const _otroChat = 'intercambio-2';

SocketService _servicioListo() {
  dotenv.loadFromString(
    envString: 'API_URL=http://127.0.0.1:1/api\nSOCKET_URL=http://127.0.0.1:1',
  );
  final servicio = SocketService.instance;
  addTearDown(servicio.disconnect);
  return servicio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SocketService.instance.disconnect();
    dotenv.clean();
  });

  group('antes de inicializar', () {
    test('pedir el socket avisa en vez de devolver nulo', () {
      final servicio = _servicioListo();
      expect(() => servicio.socket, throwsA(isA<StateError>()));
    });

    test('salir de una conversación no revienta', () {
      // Puede pasar de verdad: una pantalla de chat que se cierra durante el
      // cierre de sesión llama a `leaveChat` cuando ya no hay socket.
      final servicio = _servicioListo();
      expect(() => servicio.leaveChat(_chat), returnsNormally);
    });

    test('desconectar dos veces seguidas no revienta', () {
      final servicio = _servicioListo();
      expect(servicio.disconnect, returnsNormally);
      expect(servicio.disconnect, returnsNormally);
    });

    test('nada está listo para conversar', () {
      final servicio = _servicioListo();
      expect(servicio.isChatReady(_chat), isFalse);
      expect(servicio.isConnected, isFalse);
    });
  });

  group('la conexión lleva la sesión que corresponde', () {
    test('el token viaja en la autenticación y en la cabecera', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');

      expect(servicio.socket.auth, {'token': 'token-abc'});
      final opciones = servicio.socket.io.options ?? const {};
      expect(
        (opciones['extraHeaders'] as Map?)?['Authorization'],
        'Bearer token-abc',
      );
    });

    test('fuerza conexión nueva y no se conecta sola', () {
      // `forceNew` existe para que el caché por origen no conserve el JWT de
      // una sesión cerrada (T-013), y `autoConnect` desactivado para que la
      // conexión ocurra cuando la app lo decide, no al construir el objeto.
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');

      final opciones = servicio.socket.io.options ?? const {};
      expect(opciones['forceNew'], isTrue);
      expect(opciones['autoConnect'], isFalse);
      expect(opciones['transports'], ['websocket']);
    });

    test('después de desconectar, el socket deja de existir', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      expect(() => servicio.socket, returnsNormally);

      servicio.disconnect();
      expect(() => servicio.socket, throwsA(isA<StateError>()));
      expect(servicio.isConnected, isFalse);
    });

    test('reinicializar con el mismo token conserva el socket', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      final primero = servicio.socket;

      servicio.initialize(token: 'token-abc');
      expect(identical(servicio.socket, primero), isTrue);
    });
  });

  group('enviar un mensaje', () {
    // ADVERTENCIA, comprobada rompiendo el código a propósito: aquí **no** se
    // puede aislar la guarda del contenido vacío. `sendMessage` comprueba dos
    // cosas —que el contenido no esté en blanco y que la conversación esté
    // lista— y sin servidor la segunda siempre falla, así que el envío
    // devuelve `false` por ese camino aunque se quite la primera guarda. Se
    // verificó: al borrar `message.isEmpty` del código, estas pruebas seguían
    // pasando. Por eso se describen por lo que de verdad vigilan —que nada
    // sale mientras la conversación no esté lista— y no por lo que parecía.
    // La guarda del contenido vacío se ejercita en el recorrido Playwright del
    // chat, que sí levanta una API real.
    test('nada sale mientras la conversación no está lista, con cualquier '
        'contenido', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');

      for (final contenido in ['', '   ', '\n', '\t  \n', 'hola', '交換']) {
        expect(
          servicio.sendMessage(contenido, _chat),
          isFalse,
          reason: 'el contenido ${contenido.codeUnits} no debería salir',
        );
      }
    });

    test('tampoco sale entrando a la conversación, si el socket no confirmó',
        () {
      // Entrar no basta: hace falta que el servidor responda `joined-chat`.
      // Esta es la diferencia que evita que la cabecera diga "Chat conectado"
      // antes de tiempo.
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      servicio.joinChat(_chat);

      expect(servicio.sendMessage('hola', _chat), isFalse);
    });

    test('rechaza el envío sin haber inicializado, en vez de reventar', () {
      // Sin socket, `sendMessage` podría lanzar al pedir `socket`. Devuelve
      // `false` porque la comprobación de "listo" corta antes.
      final servicio = _servicioListo();
      expect(servicio.sendMessage('hola', _chat), isFalse);
      expect(() => servicio.sendMessage('hola', _chat), returnsNormally);
    });
  });

  group('entrar y salir de conversaciones', () {
    test('entrar sin conexión no marca la conversación como lista', () {
      // El aviso de "Chat conectado" depende de `isChatReady`. Si entrar
      // bastara para ponerlo en verde, la cabecera mentiría mientras el socket
      // todavía no confirma nada.
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');

      servicio.joinChat(_chat);
      expect(servicio.isChatReady(_chat), isFalse);
    });

    test('ninguna conversación queda lista, ni la propia ni otra', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      servicio.joinChat(_chat);

      expect(servicio.isChatReady(_chat), isFalse);
      expect(servicio.isChatReady(_otroChat), isFalse);
    });

    test('salir de una conversación ajena no toca la pendiente', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      servicio.joinChat(_chat);

      expect(() => servicio.leaveChat(_otroChat), returnsNormally);
      expect(servicio.isChatReady(_chat), isFalse);
    });

    test('entrar y salir repetidas veces no revienta', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');

      expect(() {
        for (var i = 0; i < 5; i++) {
          servicio.joinChat(_chat);
          servicio.leaveChat(_chat);
        }
      }, returnsNormally);
    });
  });

  group('el canal de avisos de intercambios', () {
    test('admite varios oyentes a la vez', () {
      // Las tres listas del cliente —Chats, Enviadas y Recibidas— se suscriben
      // al mismo canal. Si no fuera de difusión, la segunda reventaría.
      final servicio = _servicioListo();

      final primera = servicio.exchangeActivity.listen((_) {});
      final segunda = servicio.exchangeActivity.listen((_) {});
      addTearDown(primera.cancel);
      addTearDown(segunda.cancel);

      expect(servicio.exchangeActivity.isBroadcast, isTrue);
    });

    test('sobrevive a desconectar y volver a inicializar', () {
      final servicio = _servicioListo();
      servicio.initialize(token: 'token-abc');
      final suscripcion = servicio.exchangeActivity.listen((_) {});
      addTearDown(suscripcion.cancel);

      servicio.disconnect();
      expect(() => servicio.initialize(token: 'token-def'), returnsNormally);
    });
  });

  group('el aviso de actividad', () {
    test('distingue un mensaje de un cambio de estado', () {
      const mensaje = ExchangeActivity(
        chatExchangeId: _chat,
        esMensaje: true,
      );
      const estado = ExchangeActivity(
        chatExchangeId: _chat,
        esMensaje: false,
        estado: 'accepted',
      );

      expect(mensaje.esMensaje, isTrue);
      expect(mensaje.estado, isNull);
      expect(estado.esMensaje, isFalse);
      expect(estado.estado, 'accepted');
    });
  });
}
