import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_grid_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a concise product summary and opens the product',
      (tester) async {
    var taps = 0;
    final product = Product(
      id: 'product-1',
      title: 'Claymore manga volumen 09',
      typeOf: 'Manga',
      description: 'Descripción',
      tomo: 9,
      sizeOf: 'Ninguno',
      gender: 'Acción',
      demographic: 'Shonen',
      tags: const ['Claymore'],
      images: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 340,
              child: ProductGridCard(
                product: product,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(product.title), findsOneWidget);
    expect(find.text('Shonen · Vol. 09'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);

    await tester.tap(find.byType(ProductGridCard));
    await tester.pump();
    expect(taps, 1);
  });
}
