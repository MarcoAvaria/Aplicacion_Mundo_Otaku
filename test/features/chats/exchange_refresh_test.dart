import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/exchange_list_support.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _pullDown(WidgetTester tester, Widget content) async {
  var refreshes = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: SizedBox(
            height: 600,
            child: ExchangeRefreshIndicator(
              tokens: InkTokens.of(context),
              onRefresh: () async => refreshes++,
              child: content,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.fling(find.byType(ExchangeRefreshIndicator), const Offset(0, 320), 1200);
  await tester.pumpAndSettle();

  return refreshes;
}

void main() {
  testWidgets('la bandeja vacía también se puede arrastrar para refrescar',
      (tester) async {
    final refreshes = await _pullDown(
      tester,
      const ScrollableStatus(
        child: ListStatusView(message: 'No tienes solicitudes pendientes.'),
      ),
    );

    expect(refreshes, 1);
  });

  testWidgets('una lista corta también se puede arrastrar para refrescar',
      (tester) async {
    final refreshes = await _pullDown(
      tester,
      ListView(
        physics: ExchangeRefreshIndicator.physics,
        children: const [SizedBox(height: 60, child: Text('Un intercambio'))],
      ),
    );

    expect(refreshes, 1);
  });

  testWidgets('el mensaje de estado se sigue leyendo dentro del arrastre',
      (tester) async {
    await _pullDown(
      tester,
      const ScrollableStatus(
        child: ListStatusView(message: 'No tienes solicitudes pendientes.'),
      ),
    );

    expect(find.text('No tienes solicitudes pendientes.'), findsOneWidget);
  });
}
