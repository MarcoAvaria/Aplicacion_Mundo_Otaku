import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_primary_button.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const etiqueta = 'Iniciar sesión';

Future<void> _montar(
  WidgetTester tester, {
  required bool ocupado,
  VoidCallback? alPulsar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: InkPrimaryButton(
            tokens: InkTokens.of(context),
            label: etiqueta,
            isBusy: ocupado,
            onPressed: alPulsar,
          ),
        ),
      ),
    ),
  );
}

void main() {
  /// El botón tiene que anunciarse como botón **y** ofrecer la acción de
  /// pulsar. No basta con lo primero: `excludeSemantics: true` descarta el
  /// subárbol, y con él la acción que aportaba el `InkWell`, de modo que el
  /// botón quedaba anunciado sin nada que se pudiera hacer con él.
  ///
  /// Se detectó leyendo el árbol de accesibilidad real de un dispositivo
  /// Android, donde este nodo aparecía con `clickable="false"` mientras que las
  /// entradas del menú lateral sí eran accionables. Estas pruebas fijan el
  /// contrato para que no se vuelva a perder.
  testWidgets('se anuncia como botón con su nombre', (tester) async {
    await _montar(tester, ocupado: false, alPulsar: () {});

    final semantica =
        tester.getSemantics(find.byType(InkPrimaryButton)).getSemanticsData();
    expect(semantica.label, etiqueta);
    expect(semantica.flagsCollection.isButton, isTrue);
    expect(semantica.flagsCollection.isEnabled, Tristate.isTrue);
  });

  testWidgets('ofrece la acción de pulsar', (tester) async {
    await _montar(tester, ocupado: false, alPulsar: () {});

    final semantica =
        tester.getSemantics(find.byType(InkPrimaryButton)).getSemanticsData();
    expect(semantica.hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('la acción de pulsar llega al callback', (tester) async {
    var pulsaciones = 0;
    await _montar(tester, ocupado: false, alPulsar: () => pulsaciones += 1);

    final nodo = tester.getSemantics(find.byType(InkPrimaryButton));
    nodo.owner!.performAction(nodo.id, SemanticsAction.tap);
    await tester.pump();

    expect(pulsaciones, 1);
  });

  testWidgets('mientras la petición viaja se anuncia deshabilitado y sin acción',
      (tester) async {
    await _montar(tester, ocupado: true);

    final semantica =
        tester.getSemantics(find.byType(InkPrimaryButton)).getSemanticsData();
    expect(semantica.flagsCollection.isEnabled, Tristate.isFalse);
    expect(semantica.hasAction(SemanticsAction.tap), isFalse);
  });
}
