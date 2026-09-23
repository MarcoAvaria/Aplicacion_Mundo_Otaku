import 'package:flutter/material.dart';

/// Colores y grosores de la dirección "Tinta y Neón", resueltos por modo.
///
/// En oscuro el neón nunca rellena superficies grandes: se usa en bordes,
/// iconos y texto, y los fondos teñidos salen del contenedor magenta del tema.
class InkTokens {
  const InkTokens({
    required this.paper,
    required this.panel,
    required this.ink,
    required this.onInk,
    required this.borderWidth,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.shadow,
    required this.chipSelected,
    required this.chipSelectedBorder,
    required this.chipSelectedText,
    required this.avatarWash,
    required this.halftone,
  });

  final Color paper;
  final Color panel;
  final Color ink;

  /// Color de texto legible **sobre** `ink`.
  ///
  /// Hacía falta porque `ink` es oscuro en los dos modos, mientras que `paper`
  /// —que se estaba usando para esto— se invierte: en claro es casi blanco y
  /// sirve, pero en oscuro es casi negro y el texto desaparecía sobre la barra.
  /// Es el mismo par que `accent`/`onAccent`, que ya existía.
  final Color onInk;
  final double borderWidth;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color shadow;
  final Color chipSelected;
  final Color chipSelectedBorder;
  final Color chipSelectedText;
  final Color avatarWash;
  final Color halftone;

  factory InkTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const InkTokens(
        paper: Color(0xFF131117),
        panel: Color(0xFF1B1820),
        ink: Color(0xFF2C2833),
        onInk: Color(0xFFF1EEF5),
        borderWidth: 1.8,
        text: Color(0xFFF1EEF5),
        muted: Color(0xFF9089A0),
        accent: Color(0xFF38182D),
        onAccent: Color(0xFFFF3FA0),
        shadow: Color(0xFF000000),
        chipSelected: Color(0xFF38182D),
        chipSelectedBorder: Color(0xFFFF3FA0),
        chipSelectedText: Color(0xFFFF3FA0),
        avatarWash: Color(0xFF221C29),
        halftone: Color(0xFFFF3FA0),
      );
    }

    return const InkTokens(
      paper: Color(0xFFFDF9FC),
      panel: Color(0xFFFFFFFF),
      ink: Color(0xFF241626),
      onInk: Color(0xFFFDF9FC),
      borderWidth: 2.5,
      text: Color(0xFF241626),
      muted: Color(0xFF6E5F6C),
      accent: Color(0xFF9A1E74),
      onAccent: Color(0xFFFFFFFF),
      shadow: Color(0xFF241626),
      chipSelected: Color(0xFF9A1E74),
      chipSelectedBorder: Color(0xFF241626),
      chipSelectedText: Color(0xFFFFFFFF),
      avatarWash: Color(0xFFF6EAF2),
      halftone: Color(0xFF9A1E74),
    );
  }
}

/// Botón cuadrado de tinta que abre el menú lateral.
class InkMenuButton extends StatelessWidget {
  const InkMenuButton({
    super.key,
    required this.tokens,
    required this.onPressed,
  });

  final InkTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Abrir menú',
        child: Material(
          color: tokens.panel,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.ink, width: 2.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bar(color: tokens.ink, widthFactor: 1),
                  const SizedBox(height: 5),
                  _Bar(color: tokens.ink, widthFactor: 0.6),
                  const SizedBox(height: 5),
                  _Bar(color: tokens.ink, widthFactor: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(height: 2.5, color: color),
    );
  }
}

/// Botón de acción con sombra dura impresa.
///
/// La sombra va en un contenedor externo: dentro del mismo `BoxDecoration` que
/// el relleno se dibujaría por encima del color del `Material`.
class InkHardButton extends StatelessWidget {
  const InkHardButton({
    super.key,
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final InkTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Material(
          color: tokens.accent,
          shape: Border.all(color: tokens.ink, width: 2.5),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: tokens.onAccent),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
