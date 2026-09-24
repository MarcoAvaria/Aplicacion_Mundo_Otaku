
import 'package:flutter/material.dart';

/// Tipografías empaquetadas en la aplicación.
///
/// Antes se traían con `google_fonts`, que las descarga por red la primera vez
/// que se abren: sin conexión no llegaban, y el primer render mostraba una
/// fuente de reemplazo. Los archivos viven en `assets/fonts/` y se declaran en
/// `pubspec.yaml`.
///
/// Son fuentes variables, así que el peso y el ancho se piden con
/// `fontVariations`. `fontWeight` se mantiene además porque es lo que leen las
/// pruebas y las herramientas de accesibilidad.
abstract final class AppFonts {
  /// Títulos. Eje de ancho `wdth` entre 75 y 200.
  static const display = 'Bricolage Grotesque';

  /// Texto corrido.
  static const body = 'Work Sans';

  /// Subconjunto con los caracteres 交換 · 교환, y nada más.
  ///
  /// Se pidió a Google Fonts recortada a esos glifos, de ahí que pese 6 KB en
  /// vez de varios megabytes. **Si se necesita otro carácter japonés o coreano
  /// hay que volver a generar el archivo**, porque este no lo contiene.
  static const cjk = 'Noto Sans KR';

  /// Ancho de los títulos, en el eje `wdth` de la fuente variable.
  ///
  /// El diseño pide 88, algo condensado. Se dejó en 100 porque en Flutter
  /// 3.16.8 el motor angosta los glifos pero sigue calculando el avance del
  /// espacio con la instancia por omisión: entre palabras queda un hueco
  /// visiblemente grande, y `wordSpacing` no alcanza a compensarlo.
  ///
  /// Es una limitación de la versión, no del diseño. Al actualizar Flutter,
  /// basta volver este valor a 88 y comprobar el espaciado entre palabras.
  static const displayWidth = 100.0;

  static TextStyle displayStyle({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    double width = displayWidth,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontVariations: [
        FontVariation('wght', fontWeight.value.toDouble()),
        FontVariation('wdth', width),
      ],
    );
  }

  static TextStyle bodyStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: body,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontVariations: [FontVariation('wght', fontWeight.value.toDouble())],
    );
  }
}
