import 'package:formz/formz.dart';

/// Errores posibles del número de tomo.
enum TomoError { faltante, formato, negativo, fueraDeRango }

/// El número de volumen de un manga o manhwa, igual que el tomo de un libro.
///
/// **El tomo 0 existe**: hay obras que, ya avanzada la serie, publican un
/// tomo 0 con una historia previa al comienzo de la principal. Lo que nunca
/// existe es un tomo negativo.
///
/// Por eso la entrada guarda **el texto escrito** y no un número. Con un
/// entero no había forma de distinguir "tomo 0" de "no lo llenaste": los dos
/// eran 0, y la app usaba ese mismo 0 para decir "no aplica" en los productos
/// que no son un tomo. Con el texto, vacío y "0" son cosas distintas.
///
/// El tomo es obligatorio **solo si el producto es un manga**. Para Ropa, Taza
/// y Otros puede quedar vacío, y entonces se guarda 0, que para ellos sigue
/// significando "no aplica" (ver `Product.muestraTomo`).
class Tomo extends FormzInput<String, TomoError> {
  const Tomo.pure({this.esManga = false}) : super.pure('');

  const Tomo.dirty(String value, {this.esManga = false}) : super.dirty(value);

  /// El mayor número que cabe en la columna `int` de PostgreSQL. Un número
  /// mayor lo rechazaría la base, así que se detiene aquí con un mensaje claro.
  static const maximo = 2147483647;

  /// Si el producto es un manga, y por lo tanto el tomo es obligatorio.
  final bool esManga;

  /// El número escrito, o `null` si el campo está vacío o no es un número.
  int? get numero => int.tryParse(value.trim());

  String? get errorMessage {
    if (isValid || isPure) return null;

    return switch (displayError) {
      TomoError.faltante => 'Un manga necesita su número de tomo (puede ser 0)',
      TomoError.formato => 'Escribe solo el número del tomo',
      TomoError.negativo => 'El tomo no puede ser negativo',
      TomoError.fueraDeRango => 'Ese número de tomo es demasiado grande',
      null => null,
    };
  }

  @override
  TomoError? validator(String value) {
    final texto = value.trim();
    if (texto.isEmpty) return esManga ? TomoError.faltante : null;

    final numero = int.tryParse(texto);
    if (numero == null) {
      // "1.5", "abc", "3a"... Pero un número entero demasiado largo también
      // falla al leerse: se distingue por su forma, para no decirle a quien
      // escribió puros dígitos que no escribió un número.
      return RegExp(r'^[+-]?\d+$').hasMatch(texto)
          ? (texto.startsWith('-')
              ? TomoError.negativo
              : TomoError.fueraDeRango)
          : TomoError.formato;
    }
    if (numero < 0) return TomoError.negativo;
    if (numero > maximo) return TomoError.fueraDeRango;

    return null;
  }
}
