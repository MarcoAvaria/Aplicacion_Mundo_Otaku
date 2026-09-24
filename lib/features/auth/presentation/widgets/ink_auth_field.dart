import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';

/// Campo de texto del acceso y el registro, en la dirección "Tinta y Neón".
///
/// La etiqueta va dentro de `InputDecoration.label` y **siempre se construye**,
/// flotando sobre el borde cuando el campo tiene foco o contenido. Eso no es
/// solo estético: es lo que mantiene el nombre accesible del campo en los
/// cuatro estados. Pasarla como `hintText` no sirve, porque Material deja de
/// construir ese widget al escribir y el campo se queda sin nombre; pasarla
/// como etiqueta que no flota tampoco, porque se oculta al enfocar. Ambos
/// caminos se probaron y fallaron (ver `docs/RECORRIDOS_PLAYWRIGHT_TRAS_REDISENO.md`).
///
/// Se ve en mayúsculas, pero `semanticsLabel` conserva el texto original, que
/// es el que buscan los recorridos con `getByLabel('El correo de tu cuenta')`.
class InkAuthField extends StatelessWidget {
  const InkAuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.errorMessage,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorMessage;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.3,
      color: tokens.muted,
    );

    OutlineInputBorder box(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: tokens.halftone,
      style: AppFonts.bodyStyle(
        fontSize: 15,
        letterSpacing: 0,
        color: tokens.text,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: tokens.panel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        label: Text(label.toUpperCase(), semanticsLabel: label),
        labelStyle: labelStyle,
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => labelStyle.copyWith(
            color: states.contains(WidgetState.error)
                ? tokens.halftone
                : states.contains(WidgetState.focused)
                    ? tokens.halftone
                    : tokens.muted,
          ),
        ),
        errorText: errorMessage,
        errorStyle: TextStyle(fontSize: 11.5, color: tokens.halftone),
        enabledBorder: box(tokens.ink, tokens.borderWidth),
        focusedBorder: box(tokens.halftone, tokens.borderWidth),
        errorBorder: box(tokens.halftone, tokens.borderWidth),
        focusedErrorBorder: box(tokens.halftone, tokens.borderWidth),
      ),
    );
  }
}
