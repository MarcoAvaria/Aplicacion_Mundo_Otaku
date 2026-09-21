import 'package:aplicacion_mundo_otaku/features/shared/widgets/my_field_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const etiqueta = 'El correo de tu cuenta';

Future<TextEditingController> _montar(
  WidgetTester tester, {
  String texto = '',
}) async {
  final controller = TextEditingController(text: texto);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyFieldText(varTextCtrl: controller, label: etiqueta),
      ),
    ),
  );
  return controller;
}

/// El nombre puede vivir en un nodo vecino del campo: Flutter Web lo fusiona
/// con el `input` al construir el árbol del navegador, que es lo que ven tanto
/// un lector de pantalla como Playwright. Por eso se busca por etiqueta y no se
/// exige que el nodo del `TextFormField` la lleve en el árbol de widgets.
void _esperarEtiquetaEnElCampo(WidgetTester tester) {
  expect(find.bySemanticsLabel(etiqueta), findsOneWidget);
}

void main() {
  testWidgets('se anuncia con su etiqueta cuando está vacío', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    _esperarEtiquetaEnElCampo(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta al estar enfocado', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    _esperarEtiquetaEnElCampo(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta cuando ya tiene contenido', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester, texto: 'alguien@mundo-otaku.test');

    // El texto de ayuda deja de dibujarse cuando hay contenido. Si la etiqueta
    // dependiera solo de él, el campo quedaría sin nombre accesible justo
    // después de escribir, que es cuando más se necesita para identificarlo.
    _esperarEtiquetaEnElCampo(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta al escribir dentro del campo',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    await tester.enterText(find.byType(TextFormField), 'hola@correo.test');
    await tester.pumpAndSettle();

    _esperarEtiquetaEnElCampo(tester);

    handle.dispose();
  });
}
