// Banco de pruebas visual de pantallas completas.
//
// Monta la pantalla con un repositorio de productos falso, sin API ni sesión
// iniciada, para comparar el resultado contra las maquetas.
// No forma parte de la aplicación.
//
//   flutter run -d chrome -t tool/vista_pantallas.dart
//
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
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
        productsRepositoryProvider.overrideWithValue(_SampleRepository()),
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
    for (final location in const [
      AppRoutes.chatList,
      AppRoutes.requestedList,
      AppRoutes.receivedList,
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
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: const Center(child: Text('Fuera del alcance de esta vista')),
      ),
    ),
    GoRoute(
      path: AppRoutes.otherProductPattern,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Producto de otro')),
        body: const Center(child: Text('Fuera del alcance de esta vista')),
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
  Future<List<Product>> getProductsByPage({int limit = 10, int offset = 0}) async {
    if (offset > 0) return [];
    return _samples;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta vista');
}

final _owner = User(
  id: 'otro-usuario',
  email: 'demo@mundootaku.cl',
  fullName: 'Sofía R.',
  token: '',
  roles: const ['user'],
);

Product _mine(String id, String title, String type, int tomo, String demo) => Product(
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
    title: 'Solo Leveling',
    typeOf: 'Manga',
    description: '',
    tomo: 1,
    sizeOf: '',
    gender: 'Accion peleas',
    demographic: 'Seinen',
    tags: const [],
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
