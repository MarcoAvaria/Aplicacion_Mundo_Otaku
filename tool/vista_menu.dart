// Banco de pruebas visual del menú lateral.
//
// Monta únicamente el menú, sin API ni sesión iniciada, para comparar las dos
// variantes contra las maquetas. No forma parte de la aplicación.
//
//   flutter run -d chrome -t tool/vista_menu.dart
//
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initEnvironment();
  runApp(const ProviderScope(child: _MenuPreviewApp()));
}

final _router = GoRouter(
  initialLocation: AppRoutes.discover,
  routes: [
    for (final location in const [
      AppRoutes.discover,
      AppRoutes.products,
      AppRoutes.chatList,
      AppRoutes.requestedList,
      AppRoutes.receivedList,
      AppRoutes.login,
    ])
      GoRoute(
        path: location,
        builder: (context, state) => _Stage(location: location),
      ),
  ],
);

class _MenuPreviewApp extends ConsumerWidget {
  const _MenuPreviewApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vista del menú',
      debugShowCheckedModeBanner: false,
      theme: EditorialAppTheme.light,
      darkTheme: EditorialAppTheme.dark,
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: _router,
    );
  }
}

class _Stage extends StatefulWidget {
  const _Stage({required this.location});

  final String location;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: StyledNavigationDrawer(scaffoldKey: _scaffoldKey),
      appBar: AppBar(title: const Text('Vista del menú')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.location, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Text('Abrir menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
