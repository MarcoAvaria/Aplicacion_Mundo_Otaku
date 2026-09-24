import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_navigation_drawer.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/webtoon_navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// El interruptor de modo oscuro se accionaba bien con el dedo, pero para un
/// lector de pantalla no era un control utilizable: su nodo llegaba **sin
/// nombre**, y la palabra "Modo oscuro" quedaba absorbida por el nodo grande
/// de la ruta del menú, junto al resto de los textos sin acción.
///
/// El resultado era un interruptor anónimo: se anunciaba el estado, pero no de
/// qué. Estas pruebas fijan lo que un lector de pantalla necesita —un solo nodo
/// con nombre, estado conmutable y acción— y lo comprueban **accionándolo por
/// la vía de accesibilidad**, no tocando la pantalla, que es justamente el
/// camino que estaba roto.
void main() {
  for (final menu in _menus) {
    group('Menú ${menu.nombre}', () {
      testWidgets('el modo oscuro es un interruptor con nombre', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrirMenu(tester, menu.construir);

        final datos = tester.semantics
            .find(find.byType(Switch))
            .getSemanticsData();

        expect(datos.label, 'Modo oscuro',
            reason: 'el interruptor llega sin nombre y la etiqueta se queda '
                'en otro nodo, así que se anuncia el estado pero no de qué');
        // Antes eran dos banderas (`hasToggledState` e `isToggled`); ahora son
        // un solo `Tristate`, donde `none` significa "no es conmutable".
        expect(datos.flagsCollection.isToggled, isNot(Tristate.none),
            reason: 'sin estado conmutable no se puede saber si está activo');
        expect(datos.hasAction(SemanticsAction.tap), isTrue,
            reason: 'sin acción no se puede accionar desde el lector');

        semantica.dispose();
      });

      testWidgets('accionarlo desde accesibilidad cambia el tema',
          (tester) async {
        final semantica = tester.ensureSemantics();
        final contenedor = await _abrirMenu(tester, menu.construir);

        // El modo de partida es `system`, y en las pruebas el sistema está en
        // claro: lo que importa es que el interruptor arranque apagado.
        final nodo = tester.semantics.find(find.byType(Switch));
        expect(nodo.getSemanticsData().flagsCollection.isToggled, Tristate.isFalse);

        // Se acciona por la vía del lector de pantalla, no con un toque: es
        // justamente el camino que no servía.
        nodo.owner!.performAction(nodo.id, SemanticsAction.tap);
        await tester.pumpAndSettle();

        expect(contenedor.read(appThemeModeProvider), ThemeMode.dark);
        expect(
          tester.semantics
              .find(find.byType(Switch))
              .getSemanticsData()
              .flagsCollection.isToggled,
          Tristate.isTrue,
          reason: 'el estado anunciado debe seguir al tema, no quedarse atrás',
        );

        semantica.dispose();
      });
    });
  }
}

typedef _Constructor = Widget Function(GlobalKey<ScaffoldState> llave);

class _Menu {
  const _Menu(this.nombre, this.construir);
  final String nombre;
  final _Constructor construir;
}

const _menus = <_Menu>[
  _Menu('Capítulos', _construirInk),
  _Menu('Webtoon', _construirWebtoon),
];

Widget _construirInk(GlobalKey<ScaffoldState> llave) =>
    InkNavigationDrawer(scaffoldKey: llave);

Widget _construirWebtoon(GlobalKey<ScaffoldState> llave) =>
    WebtoonNavigationDrawer(scaffoldKey: llave);

Future<ProviderContainer> _abrirMenu(
  WidgetTester tester,
  _Constructor construir,
) async {
  final llave = GlobalKey<ScaffoldState>();
  final enrutador = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          key: llave,
          drawer: construir(llave),
          body: const SizedBox.shrink(),
        ),
      ),
    ],
  );
  final contenedor = ProviderContainer(
    overrides: [authProvider.overrideWith((ref) => _SesionFalsa())],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: contenedor,
      child: MaterialApp.router(routerConfig: enrutador),
    ),
  );
  await tester.pumpAndSettle();
  llave.currentState!.openDrawer();
  await tester.pumpAndSettle();
  return contenedor;
}

/// Sesión falsa: el menú solo necesita un nombre para su cabecera.
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
