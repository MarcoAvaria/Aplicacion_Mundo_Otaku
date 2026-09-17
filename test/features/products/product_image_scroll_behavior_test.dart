import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_image_scroll_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final device in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('permite avanzar y volver entre fotos con ${device.name}',
        (tester) async {
      final controller = PageController(viewportFraction: 0.7);
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 300,
            child: PageView(
              controller: controller,
              scrollBehavior: const ProductImageScrollBehavior(),
              children: const [
                ColoredBox(color: Colors.red),
                ColoredBox(color: Colors.blue),
              ],
            ),
          ),
        ),
      ));

      await tester.drag(find.byType(PageView), const Offset(-420, 0),
          kind: device);
      await tester.pumpAndSettle();
      expect(controller.page, 1);
      await tester.drag(find.byType(PageView), const Offset(420, 0),
          kind: device);
      await tester.pumpAndSettle();
      expect(controller.page, 0);
    });
  }
}
