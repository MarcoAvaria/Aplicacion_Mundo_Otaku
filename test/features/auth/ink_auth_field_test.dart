import 'package:aplicacion_mundo_otaku/features/auth/presentation/widgets/ink_auth_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const etiqueta = 'El correo de tu cuenta';

Future<void> _montar(WidgetTester tester, {String texto = ''}) async {
  final controller = TextEditingController(text: texto);
  final focusNode = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InkAuthField(
          label: etiqueta,
          controller: controller,
          focusNode: focusNode,
        ),
      ),
    ),
  );
}

/// El nombre puede vivir en un nodo vecino del campo: Flutter Web lo fusiona
/// con el `input` al construir el árbol del navegador, que es lo que ven tanto
/// un lector de pantalla como Playwright con `getByLabel`.
void _esperarEtiqueta(WidgetTester tester) {
  expect(find.bySemanticsLabel(etiqueta), findsOneWidget);
}

void main() {
  testWidgets('se anuncia con su etiqueta cuando está vacío', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    _esperarEtiqueta(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta al estar enfocado', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    _esperarEtiqueta(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta cuando ya tiene contenido', (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester, texto: 'alguien@mundo-otaku.test');

    _esperarEtiqueta(tester);

    handle.dispose();
  });

  testWidgets('conserva su etiqueta al escribir dentro del campo',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    await tester.enterText(find.byType(TextFormField), 'hola@correo.test');
    await tester.pumpAndSettle();

    _esperarEtiqueta(tester);

    handle.dispose();
  });

  testWidgets('la etiqueta se dibuja en mayúsculas sin perder su nombre',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _montar(tester);

    expect(find.text(etiqueta.toUpperCase()), findsOneWidget);
    _esperarEtiqueta(tester);

    handle.dispose();
  });
}
