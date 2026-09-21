import 'package:flutter/material.dart';

/// Trama de puntos: el equivalente a la screentone del manga impreso.
class HalftonePainter extends CustomPainter {
  const HalftonePainter({
    required this.color,
    this.spacing = 7,
    this.radius = 1.1,
    this.opacity = 0.38,
  });

  final Color color;
  final double spacing;
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(opacity);
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HalftonePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.spacing != spacing ||
      oldDelegate.radius != radius ||
      oldDelegate.opacity != opacity;
}
