import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Mantiene los gestos táctiles de Flutter y permite arrastrar fotos con ratón.
class ProductImageScrollBehavior extends MaterialScrollBehavior {
  const ProductImageScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}
