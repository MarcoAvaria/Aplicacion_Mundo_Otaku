import 'package:aplicacion_mundo_otaku/features/shared/widgets/custom_product_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'conserva la edición activa y sincroniza cambios externos al perder foco',
    (tester) async {
      final externalValue = ValueNotifier('Valor inicial');
      final reportedValues = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: externalValue,
              builder: (context, value, _) => Column(
                children: [
                  CustomProductField(
                    label: 'Nombre',
                    initialValue: value,
                    onChanged: reportedValues.add,
                  ),
                  TextButton(
                    onPressed: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: const Text('Fuera del campo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Edición local');
      externalValue.value = 'Respuesta externa atrasada';
      await tester.pump();

      expect(find.text('Edición local'), findsOneWidget);
      expect(reportedValues, contains('Edición local'));

      await tester.tap(find.text('Fuera del campo'));
      await tester.pump();
      externalValue.value = 'Valor externo definitivo';
      await tester.pump();

      expect(find.text('Valor externo definitivo'), findsOneWidget);
      expect(reportedValues.last, 'Edición local');
    },
  );
}
