import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';

/// Lomo vertical con 交換 · 교환, "intercambio" en japonés y en coreano.
///
/// El guiño a las dos culturas que conviven en la app: el manga japonés y el
/// manhwa coreano. Se escribe de arriba hacia abajo, como el lomo de un tomo.
///
/// En CSS esto sería `writing-mode: vertical-rl`, que Flutter no tiene, y
/// `RotatedBox` acostaría los glifos. Por eso los caracteres se apilan uno a
/// uno, que además es como se componen de verdad.
class VerticalCjkLabel extends StatelessWidget {
  const VerticalCjkLabel({
    super.key,
    required this.color,
    this.text = '交換·교환',
    this.fontSize = 13,
  });

  final Color color;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Intercambio, escrito en japonés y coreano',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final character in text.split(''))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  character,
                  style: TextStyle(
                    fontFamily: AppFonts.cjk,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
