// La lista de mensajes del chat, sin servidor.
//
// Hasta el 2026-09-24 esa lista vivía en un `ChatController` de GetX, global y
// creado al arrancar la app, y ninguna prueba de widget la ejercitaba: solo la
// cubrían los recorridos Playwright, que necesitan una API real. Al retirar
// GetX la lista pasó a ser estado propio de la pantalla, y esta prueba la
// vigila directamente.
//
// El servidor se simula con `socket.emitEvent`, que despacha un evento a los
// manejadores registrados con `on` exactamente como si hubiera llegado por la
// red. El socket nunca se conecta: el `SOCKET_URL` apunta a un puerto cerrado y
// `autoConnect` está desactivado.
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_repository_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_read_marks_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _conversacion = 'intercambio-1';

Map<String, String> _mensaje(String texto, String autor, int minuto) => {
      'content': texto,
      'sendBy': autor,
      'timestamp': DateTime.utc(2026, 9, 24, 12, minuto).toIso8601String(),
    };

/// Hace de servidor: entrega un evento al socket como si llegara por la red.
void _servidorEnvia(String evento, Object datos) {
  SocketService.instance.socket.emitEvent([evento, datos]);
}

Future<void> _montarChat(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SesionFalsa()),
        productsRepositoryProvider.overrideWithValue(_Productos()),
        chatExchangesRepositoryProvider.overrideWithValue(_Intercambios()),
        chatReadMarksProvider.overrideWith(
          (ref) => ChatReadMarksNotifier(
            loadMarks: () async => null,
            saveMarks: (_) async {},
          ),
        ),
      ],
      child: MaterialApp(
        theme: EditorialAppTheme.light,
        home: const ChatScreen(
          conversacionId: _conversacion,
          miProductId: 'mio',
          otroProductId: 'suyo',
        ),
      ),
    ),
  );
  // Carga de los dos productos y del intercambio, que son asíncronas.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Escribe un mensaje'), findsOneWidget,
      reason: 'la conversación tendría que estar a la vista');
}

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: 'API_URL=http://127.0.0.1:1/api\nSOCKET_URL=http://127.0.0.1:1',
    );
    SocketService.instance.initialize(token: 'token-de-prueba');
  });

  tearDown(() {
    SocketService.instance.disconnect();
    dotenv.clean();
  });

  testWidgets('el historial que manda el servidor se dibuja en orden',
      (tester) async {
    await _montarChat(tester);

    _servidorEnvia('chat-history', {
      'messages': [
        _mensaje('Hola, ¿sigue disponible?', 'otro', 1),
        _mensaje('Sí, ¿cuál me ofreces?', 'yo', 2),
      ],
    });
    await tester.pump();

    final primero = find.text('Hola, ¿sigue disponible?');
    final segundo = find.text('Sí, ¿cuál me ofreces?');
    expect(primero, findsOneWidget);
    expect(segundo, findsOneWidget);
    expect(
      tester.getTopLeft(primero).dy,
      lessThan(tester.getTopLeft(segundo).dy),
    );
  });

  testWidgets('un mensaje nuevo se agrega al final, sin tocar los anteriores',
      (tester) async {
    await _montarChat(tester);
    _servidorEnvia('chat-history', {
      'messages': [_mensaje('primero', 'otro', 1)],
    });
    await tester.pump();

    _servidorEnvia('new-message', _mensaje('segundo', 'otro', 2));
    await tester.pump();

    expect(find.text('primero'), findsOneWidget);
    expect(find.text('segundo'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('primero')).dy,
      lessThan(tester.getTopLeft(find.text('segundo')).dy),
    );
  });

  testWidgets('un historial nuevo reemplaza al anterior, no se suma',
      (tester) async {
    // Pasa de verdad: al refrescar, o al reconectarse, el servidor vuelve a
    // mandar el historial completo. Si se sumara, cada reconexión duplicaría
    // la conversación entera.
    await _montarChat(tester);
    final historial = {
      'messages': [
        _mensaje('uno', 'otro', 1),
        _mensaje('dos', 'yo', 2),
      ],
    };

    _servidorEnvia('chat-history', historial);
    await tester.pump();
    _servidorEnvia('chat-history', historial);
    await tester.pump();

    expect(find.text('uno'), findsOneWidget);
    expect(find.text('dos'), findsOneWidget);
  });

  testWidgets('un historial vacío deja la conversación vacía', (tester) async {
    await _montarChat(tester);
    _servidorEnvia('chat-history', {
      'messages': [_mensaje('algo', 'otro', 1)],
    });
    await tester.pump();

    _servidorEnvia('chat-history', {'messages': <Object>[]});
    await tester.pump();

    expect(find.text('algo'), findsNothing);
  });

  testWidgets('datos malformados del servidor no revientan la pantalla',
      (tester) async {
    await _montarChat(tester);

    _servidorEnvia('chat-history', 'no es un mapa');
    _servidorEnvia('chat-history', {'messages': 'no es una lista'});
    _servidorEnvia('new-message', 42);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Escribe un mensaje'), findsOneWidget);
  });

  testWidgets('los mensajes no sobreviven a la pantalla', (tester) async {
    // La diferencia de fondo con GetX. Antes la lista vivía en un objeto
    // global: al salir de una conversación sus mensajes seguían en memoria, y
    // si otra pantalla la hubiese mostrado sin pasar por el `initState` que la
    // vaciaba, habría enseñado mensajes ajenos. Ahora es de la pantalla.
    await _montarChat(tester);
    _servidorEnvia('chat-history', {
      'messages': [_mensaje('mensaje de la conversación anterior', 'otro', 1)],
    });
    await tester.pump();
    expect(find.text('mensaje de la conversación anterior'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await _montarChat(tester);

    expect(find.text('mensaje de la conversación anterior'), findsNothing);
  });

  testWidgets('cerrar la sesión con el chat abierto no revienta al desmontarlo',
      (tester) async {
    // T-058. Es el orden real de `AuthNotifier._clearLocalSession`: primero
    // destruye el socket y recién después marca la sesión como cerrada, que es
    // lo que hace que el router desmonte el chat. Pasa cuando el token caduca
    // o se revoca con la conversación abierta (`expireSession`, ante un 401).
    await _montarChat(tester);

    SocketService.instance.disconnect();
    await tester.pumpWidget(const SizedBox());

    expect(
      tester.takeException(),
      isNull,
      reason: 'dispose del chat pidió `socket` cuando ya no existía',
    );
  });

  testWidgets('un evento que llega después de cerrar la pantalla no revienta',
      (tester) async {
    // `dispose` da de baja los manejadores; y aunque uno se escapara, cada
    // `setState` comprueba `mounted`. Con la lista local, un `setState` sobre
    // una pantalla cerrada lanzaría un error, así que se vigila.
    await _montarChat(tester);
    await tester.pumpWidget(const SizedBox());

    _servidorEnvia('new-message', _mensaje('tarde', 'otro', 5));
    _servidorEnvia('chat-history', {
      'messages': [_mensaje('tarde', 'otro', 5)],
    });
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

Product _producto(String id) => Product(
      id: id,
      title: id == 'mio' ? 'Mi tomo' : 'Komi-san Volumen 23',
      typeOf: 'Manga',
      description: '',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: const [],
      images: const [],
    );

class _Productos implements ProductsRepository {
  @override
  Future<Product> getProductById(String id) async => _producto(id);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta prueba');
}

class _Intercambios implements ChatExchangesRepository {
  @override
  Future<ChatExchange> getChatExchangeById(String id) async => ChatExchange(
        id: id,
        owner1: 'yo',
        owner2: 'otro',
        product1: 'mio',
        product2: 'suyo',
        requester1: 'suyo',
        status: 'inProgress',
        messages: const [],
      );

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta prueba');
}

class _SesionFalsa extends AuthNotifier {
  _SesionFalsa()
      : super(
          authRepository: _Inalcanzable(),
          authDataSource: _Inalcanzable(),
          secureStorage: const FlutterSecureStorage(),
        ) {
    state = AuthState(
      authStatus: AuthStatus.authenticated,
      user: User(
        id: 'yo',
        email: 'demo@mundo-otaku.demo',
        fullName: 'Usuario Demo 1',
        token: '',
        roles: const ['user'],
      ),
    );
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class _Inalcanzable implements AuthRepository, AuthDataSource {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta prueba');
}
