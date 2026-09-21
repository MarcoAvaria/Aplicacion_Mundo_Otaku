import 'package:aplicacion_mundo_otaku/features/chats/presentation/widgets/ink_unread_badge.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, int count, {bool dark = false}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: InkUnreadBadge(
              tokens: InkTokens.of(context),
              count: count,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra el número de mensajes nuevos', (tester) async {
    await _pump(tester, 3);

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('en cero muestra un 0 apagado y de borde punteado',
      (tester) async {
    await _pump(tester, 0);

    expect(find.text('0'), findsOneWidget);

    final badge = tester.widget<InkUnreadBadge>(find.byType(InkUnreadBadge));
    expect(badge.isQuiet, isTrue);

    // El círculo apagado no se rellena: solo dibuja su contorno punteado.
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('con mensajes nuevos deja de estar apagado', (tester) async {
    await _pump(tester, 1);

    final badge = tester.widget<InkUnreadBadge>(find.byType(InkUnreadBadge));
    expect(badge.isQuiet, isFalse);
  });

  testWidgets('recorta los contadores muy grandes', (tester) async {
    await _pump(tester, 130);

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('describe su estado para lectores de pantalla', (tester) async {
    final handle = tester.ensureSemantics();

    await _pump(tester, 0);
    expect(find.bySemanticsLabel('Sin mensajes nuevos'), findsOneWidget);

    await _pump(tester, 1);
    expect(find.bySemanticsLabel('1 mensaje nuevo'), findsOneWidget);

    await _pump(tester, 4);
    expect(find.bySemanticsLabel('4 mensajes nuevos'), findsOneWidget);

    handle.dispose();
  });
}
