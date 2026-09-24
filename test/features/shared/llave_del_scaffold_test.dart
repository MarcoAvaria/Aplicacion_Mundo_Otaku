import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/repositories/chat_exchanges_repository.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_repository_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_exchange_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/ink_discover_screen.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/ink_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Las pantallas con menú creaban su `GlobalKey<ScaffoldState>` **dentro de
/// `build`**, así que cada reconstrucción traía una llave nueva. Flutter no
/// puede emparejar un elemento cuya llave cambió, de modo que destruía el
/// `Scaffold` y lo volvía a crear: se perdía todo su estado.
///
/// Se notaba al cambiar de tema con el menú abierto —el menú se cerraba solo—,
/// pero lo mismo le pasaba a cualquier `SnackBar` u hoja inferior viva en ese
/// momento, y ocurría en **toda** reconstrucción, no solo al cambiar el tema.
void main() {
  for (final pantalla in _pantallas) {
    testWidgets('${pantalla.nombre}: el menú sobrevive a una reconstrucción',
        (tester) async {
      final contenedor = await _montar(tester, pantalla.construir);

      final estado = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      estado.openDrawer();
      await tester.pumpAndSettle();
      expect(estado.isDrawerOpen, isTrue);

      // Cambiar el tema es la forma más fácil de provocar la reconstrucción;
      // lo que se vigila no es el tema, sino que el Scaffold siga siendo el
      // mismo.
      contenedor.read(appThemeModeProvider.notifier).setDarkMode(true);
      await tester.pumpAndSettle();

      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
        isTrue,
        reason: 'el Scaffold se recreó y perdió su estado: la llave cambia en '
            'cada build',
      );
    });
  }
}

typedef _Constructor = Widget Function();

class _Pantalla {
  const _Pantalla(this.nombre, this.construir);
  final String nombre;
  final _Constructor construir;
}

const _pantallas = <_Pantalla>[
  _Pantalla('Mi estante', _productos),
  _Pantalla('Descubrir', _descubrir),
  _Pantalla('Chats', _chats),
  _Pantalla('Enviadas', _enviadas),
];

Widget _productos() => const InkProductsScreen();
Widget _descubrir() => const InkDiscoverScreen();
Widget _chats() => const InkChatListScreen();
Widget _enviadas() => const InkExchangeListScreen(inbox: ExchangeInbox.sent);

Future<ProviderContainer> _montar(
  WidgetTester tester,
  _Constructor construir,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final contenedor = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => _SesionFalsa()),
      productsRepositoryProvider.overrideWithValue(_SinProductos()),
      chatExchangesRepositoryProvider.overrideWithValue(_SinIntercambios()),
    ],
  );
  addTearDown(contenedor.dispose);

  final enrutador = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, __) => construir())],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: contenedor,
      child: _Aplicacion(enrutador: enrutador),
    ),
  );
  await tester.pumpAndSettle();
  return contenedor;
}

/// Reproduce lo justo de `MainApp`: el tema sale del proveedor, así que
/// cambiarlo reconstruye las pantallas igual que en la aplicación real.
class _Aplicacion extends ConsumerWidget {
  const _Aplicacion({required this.enrutador});

  final GoRouter enrutador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: enrutador,
      theme: EditorialAppTheme.light,
      darkTheme: EditorialAppTheme.dark,
      themeMode: ref.watch(appThemeModeProvider),
    );
  }
}

class _SinProductos implements ProductsRepository {
  @override
  Future<List<Product>> getProductsByPage({int limit = 10, int offset = 0}) async => [];

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta prueba');
}

class _SinIntercambios implements ChatExchangesRepository {
  @override
  Future<List<ChatExchange>> getAllChatExchanges(String id) async => [];

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
