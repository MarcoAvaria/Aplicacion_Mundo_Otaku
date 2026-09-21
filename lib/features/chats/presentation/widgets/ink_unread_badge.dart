import 'dart:math' as math;

import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';

/// Sello pequeño con la cantidad de mensajes nuevos de una conversación.
///
/// Va pegado a la esquina de la tarjeta de intercambio, como una calcomanía, sin
/// alterar el rectángulo que hay debajo. Tiene dos estados:
///
/// - **con mensajes nuevos:** círculo relleno con el acento de la marca. Es un
///   sello de 22 px, así que el magenta sigue usándose solo como acento;
/// - **en cero:** sin relleno, con el contorno punteado y el número en un gris
///   apagado. Se nota que está ahí, pero casi se mimetiza con el papel.
class InkUnreadBadge extends StatelessWidget {
  const InkUnreadBadge({
    super.key,
    required this.tokens,
    required this.count,
  });

  final InkTokens tokens;
  final int count;

  /// Diámetro del sello. Lo usa la tarjeta para calcular cuánto sobresale.
  static const double diameter = 22;

  /// Nadie escribió desde la última vez: el sello pasa a segundo plano.
  bool get isQuiet => count <= 0;

  String get _label {
    if (count <= 0) return '0';
    return count > 99 ? '99+' : '$count';
  }

  String get _semanticsLabel {
    if (count <= 0) return 'Sin mensajes nuevos';
    if (count == 1) return '1 mensaje nuevo';
    return '$count mensajes nuevos';
  }

  @override
  Widget build(BuildContext context) {
    final content = isQuiet ? _quiet() : _loud();

    return Semantics(
      label: _semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(dimension: diameter, child: content),
    );
  }

  Widget _quiet() {
    final color = tokens.muted.withOpacity(0.45);

    return CustomPaint(
      painter: _DashedCirclePainter(color: color),
      child: Center(
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _loud() {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: tokens.shadow, offset: const Offset(2, 2))
        ],
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.chipSelected,
          shape: BoxShape.circle,
          border: Border.all(color: tokens.chipSelectedBorder, width: 2),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: _label.length > 2 ? 8 : 10.5,
            fontWeight: FontWeight.w800,
            height: 1,
            color: tokens.chipSelectedText,
          ),
        ),
      ),
    );
  }
}

/// Contorno punteado del sello apagado.
///
/// Se dibuja a mano porque `Border` no ofrece trazo discontinuo.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  static const int _dashes = 12;
  static const double _gapRatio = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    const step = 2 * math.pi / _dashes;
    const dash = step * (1 - _gapRatio);

    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect.deflate(0.7), i * step, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
