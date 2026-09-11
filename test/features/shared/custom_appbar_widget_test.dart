import 'package:aplicacion_mundo_otaku/features/shared/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({VoidCallback? onSearch}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: CustomAppBar.customAppBar(
            context,
            'Catálogo',
            onSearch: onSearch,
          ),
        ),
      ),
    );
  }

  testWidgets('hides search when the screen has no search behavior',
      (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });

  testWidgets('exposes and invokes search when configured', (tester) async {
    var calls = 0;
    await tester.pumpWidget(subject(onSearch: () => calls++));

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();

    expect(calls, 1);
  });
}
