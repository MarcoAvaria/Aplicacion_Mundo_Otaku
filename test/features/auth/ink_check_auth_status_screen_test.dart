import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/login/ink_check_auth_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: InkCheckAuthStatusScreen()),
    ),
  );
}

void main() {
  testWidgets('la pantalla de carga invita a intercambiar en Mundo Otaku',
      (tester) async {
    await _montar(tester);

    // Se lee de arriba abajo: la invitación chica y la marca grande.
    final invitacion = find.text('INTERCAMBIA EN');
    final marca = find.text('Mundo Otaku');
    expect(invitacion, findsOneWidget);
    expect(marca, findsOneWidget);
    expect(
      tester.getTopLeft(invitacion).dy,
      lessThan(tester.getTopLeft(marca).dy),
      reason: 'la invitación va arriba de la marca',
    );

    // El texto anterior, "Cambia" solo, ya no aparece.
    expect(find.text('Cambia'), findsNothing);
  });

  testWidgets('para un lector de pantalla dice qué está pasando',
      (tester) async {
    final semantica = tester.ensureSemantics();
    await _montar(tester);

    // El título es decorativo: lo que se anuncia es la acción en curso.
    expect(find.bySemanticsLabel('Comprobando tu sesión'), findsOneWidget);
    semantica.dispose();
  });
}
