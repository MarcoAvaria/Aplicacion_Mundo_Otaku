// Banco de pruebas visual de pantallas completas.
//
// Monta la pantalla con un repositorio de productos falso, sin API ni sesión
// iniciada, para comparar el resultado contra las maquetas.
// No forma parte de la aplicación.
//
//   flutter run -d chrome -t tool/vista_pantallas.dart
//
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange_message.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_repository_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_exchange_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_exchange_preview_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initEnvironment();
  runApp(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => _SampleAuthNotifier()),
        productsRepositoryProvider.overrideWithValue(_SampleRepository()),
        chatExchangesRepositoryProvider
            .overrideWithValue(_SampleExchangesRepository()),
      ],
      child: const _ScreensPreviewApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: AppRoutes.discover,
  routes: [
    GoRoute(
      path: AppRoutes.discover,
      builder: (context, state) => const InkDiscoverScreen(),
    ),
    GoRoute(
      path: AppRoutes.products,
      builder: (context, state) => const InkProductsScreen(),
    ),
    GoRoute(
      path: AppRoutes.receivedList,
      builder: (context, state) =>
          const InkExchangeListScreen(inbox: ExchangeInbox.received),
    ),
    GoRoute(
      path: AppRoutes.requestedList,
      builder: (context, state) =>
          const InkExchangeListScreen(inbox: ExchangeInbox.sent),
    ),
    GoRoute(
      path: AppRoutes.previewReceivedPattern,
      builder: (context, state) => InkExchangePreviewScreen(
        chatExchangeId: state.pathParameters['id'] ?? 'no-id',
        inbox: ExchangeInbox.received,
      ),
    ),
    GoRoute(
      path: AppRoutes.previewRequestedPattern,
      builder: (context, state) => InkExchangePreviewScreen(
        chatExchangeId: state.pathParameters['id'] ?? 'no-id',
        inbox: ExchangeInbox.sent,
      ),
    ),
    GoRoute(
      path: '/vista-chat',
      builder: (context, state) => const _ChatBubblesPreview(),
    ),
    GoRoute(
      path: AppRoutes.chatList,
      builder: (context, state) => const InkChatListScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatPattern,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Necesita socket y GetX')),
      ),
    ),
    for (final location in const [
      AppRoutes.login,
    ])
      GoRoute(
        path: location,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text(location)),
          body: const Center(child: Text('Fuera del alcance de esta vista')),
        ),
      ),
    GoRoute(
      path: AppRoutes.productPattern,
      builder: (context, state) => InkProductScreen(
        productId: state.pathParameters['id'] ?? 'no-id',
      ),
    ),
    GoRoute(
      path: AppRoutes.otherProductPattern,
      builder: (context, state) => InkOtherProductScreen(
        productId: state.pathParameters['id'] ?? 'no-id',
      ),
    ),
  ],
);

class _ScreensPreviewApp extends ConsumerWidget {
  const _ScreensPreviewApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vista de pantallas',
      debugShowCheckedModeBanner: false,
      theme: EditorialAppTheme.light,
      darkTheme: EditorialAppTheme.dark,
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: _router,
    );
  }
}

/// Repositorio de muestra: entrega una única página de productos inventados.
class _SampleRepository implements ProductsRepository {
  @override
  Future<List<Product>> getProductsByPage(
      {int limit = 10, int offset = 0}) async {
    if (offset > 0) return [];
    return _samples;
  }

  @override
  Future<Product> getProductById(String id) async =>
      _samples.firstWhere((product) => product.id == id);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta vista');
}

/// Sesión falsa: evita la comprobación real y deja una persona conectada.
class _SampleAuthNotifier extends AuthNotifier {
  _SampleAuthNotifier()
      : super(
          authRepository: _AuthStub(),
          authDataSource: _AuthStub(),
          secureStorage: const FlutterSecureStorage(),
        ) {
    state = AuthState(authStatus: AuthStatus.authenticated, user: _me);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class _AuthStub implements AuthRepository, AuthDataSource {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta vista');
}

class _SampleExchangesRepository implements ChatExchangesRepository {
  @override
  Future<List<ChatExchange>> getAllChatExchanges(String id) async => _exchanges;

  @override
  Future<ChatExchange> getChatExchangeById(String id) async =>
      _exchanges.firstWhere((exchange) => exchange.id == id);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta vista');
}

final _exchanges = <ChatExchange>[
  ChatExchange(
    id: 'e1',
    owner1: 'yo',
    owner2: 'otro-usuario',
    product1: 'm1',
    product2: '1',
    requester1: '1',
    messages: const [],
    status: 'pending',
  ),
  ChatExchange(
    id: 'e2',
    owner1: 'yo',
    owner2: 'otro-usuario',
    product1: 'm2',
    product2: '4',
    requester1: '4',
    messages: const [],
    status: 'pending',
  ),
  ChatExchange(
    id: 'e3',
    owner1: 'otro-usuario',
    owner2: 'yo',
    product1: '2',
    product2: 'm3',
    requester1: 'm3',
    messages: const [],
    status: 'pending',
  ),
  // Intercambio en curso sin mensajes nuevos: el sello queda apagado.
  ChatExchange(
    id: 'e4',
    owner1: 'yo',
    owner2: 'otro-usuario',
    product1: 'm4',
    product2: '5',
    requester1: '5',
    messages: const [],
    status: 'inProgress',
  ),
  // Intercambio en curso con mensajes nuevos de la otra persona.
  ChatExchange(
    id: 'e5',
    owner1: 'yo',
    owner2: 'otro-usuario',
    product1: 'm1',
    product2: '2',
    requester1: '2',
    messages: [
      ChatExchangeMessage(
        content: '¿Te sirve el cambio?',
        sendBy: 'otro-usuario',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      ChatExchangeMessage(
        content: 'Puedo llevarlo el sábado',
        sendBy: 'otro-usuario',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatExchangeMessage(
        content: 'Dale, lo veo',
        sendBy: 'yo',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ],
    status: 'inProgress',
  ),
];

final _me = User(
  id: 'yo',
  email: 'marco@mundootaku.cl',
  fullName: 'Marco Avaria',
  token: '',
  roles: const ['user'],
);

final _owner = User(
  id: 'otro-usuario',
  email: 'demo@mundootaku.cl',
  fullName: 'Sofía R.',
  token: '',
  roles: const ['user'],
);

Product _mine(String id, String title, String type, int tomo, String demo) =>
    Product(
      id: id,
      title: title,
      typeOf: type,
      description: '',
      tomo: tomo,
      sizeOf: '',
      gender: 'Ninguno',
      demographic: demo,
      tags: const [],
      images: const [],
      user: _me,
    );

final _samples = <Product>[
  _mine('m1', 'Berserk Deluxe Vol. 3', 'Manga', 3, 'Seinen'),
  _mine('m2', 'Akira Vol. 1', 'Manga', 1, 'Seinen'),
  _mine('m3', 'Naruto Vol. 12', 'Manga', 12, 'Shonen'),
  _mine('m4', 'Taza Komi-san', 'Taza', 0, 'Ninguno'),
  Product(
    id: '1',
    title: 'Vagabond',
    typeOf: 'Manga',
    description: '',
    tomo: 7,
    sizeOf: '',
    gender: 'Accion peleas',
    demographic: 'Seinen',
    tags: const [],
    images: const [],
    user: _owner,
  ),
  Product(
    id: '2',
    title: 'Solo Leveling Vol. 1 al 6',
    typeOf: 'Manga',
    description:
        'Colección completa de los primeros seis tomos, leídos una vez y '
        'guardados en caja. Sin dobleces en el lomo.',
    tomo: 1,
    sizeOf: '',
    gender: 'Accion peleas',
    demographic: 'Seinen',
    tags: const ['manhwa', 'acción'],
    images: const [],
    user: _owner,
  ),
  Product(
    id: '3',
    title: 'Figura Rem',
    typeOf: 'Otros',
    description: '',
    tomo: 0,
    sizeOf: '',
    gender: 'Ninguno',
    demographic: 'Ninguno',
    tags: const [],
    images: const [],
    user: _owner,
  ),
  Product(
    id: '4',
    title: 'Berserk Deluxe',
    typeOf: 'Manga',
    description: '',
    tomo: 3,
    sizeOf: '',
    gender: 'Gore Terror',
    demographic: 'Seinen',
    tags: const [],
    images: const [],
    user: _owner,
  ),
  Product(
    id: '5',
    title: 'Polerón oversize',
    typeOf: 'Ropa',
    description: '',
    tomo: 0,
    sizeOf: 'L',
    gender: 'Ninguno',
    demographic: 'Ninguno',
    tags: const [],
    images: const [],
    user: _owner,
  ),
  Product(
    id: '6',
    title: 'Taza Komi-san',
    typeOf: 'Taza',
    description: '',
    tomo: 0,
    sizeOf: '',
    gender: 'Comedia',
    demographic: 'Shonen',
    tags: const [],
    images: const [],
    user: _owner,
  ),
];

/// Solo los globos del chat: la pantalla real necesita sockets y GetX.
class _ChatBubblesPreview extends StatelessWidget {
  const _ChatBubblesPreview();

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);
    final now = DateTime(2026, 9, 19, 14, 5);

    return Scaffold(
      backgroundColor: tokens.paper,
      appBar: AppBar(title: const Text('Globos del chat')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        children: [
          MessageItem(
            sentByMe: false,
            message: '¡Hola! Vi tu Berserk deluxe y me encantó. '
                '¿Sigue disponible?',
            timestamp: now,
          ),
          MessageItem(
            sentByMe: true,
            message: '¡Hola Sofía! Sí, sigue disponible. Vi tus tomos de '
                'Solo Leveling, me interesan un montón.',
            timestamp: now.add(const Duration(minutes: 3)),
          ),
          MessageItem(
            sentByMe: false,
            message: 'Perfecto. ¿Te parece si hacemos el cambio esta semana?',
            timestamp: now.add(const Duration(minutes: 4)),
          ),
        ],
      ),
    );
  }
}
