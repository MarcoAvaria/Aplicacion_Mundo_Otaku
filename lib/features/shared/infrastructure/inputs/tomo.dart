import 'package:formz/formz.dart';

/// Errores posibles del número de tomo.
///
/// Antes existía además `TomoError.format`, para cuando el valor no fuera un
/// número. Era inalcanzable —el campo ya es un `int`— y encima usaba `-1` como
/// valor centinela, así que el tomo -1 legítimo chocaba con él y se reportaba
/// como "no tiene formato de número". Se retiró junto con esa comprobación.
enum TomoError { negativo, faltante }

/// El número de volumen de un manga o manhwa, igual que el tomo de un libro.
///
/// Por eso el mínimo válido es **1** cuando el producto es un manga: no existe
/// el tomo cero. Para los demás tipos del catálogo —Ropa, Taza, Otros— el tomo
/// no significa nada, y ahí **el 0 quiere decir "no aplica"**: las fichas de
/// producto y la vista previa de intercambio ocultan la etiqueta con
/// `if (product.tomo > 0)`. Obligar a una taza a declarar "Tomo 1" habría
/// hecho que esa etiqueta apareciera y mintiera.
///
/// Lo que nunca es válido, para ningún tipo, es un tomo negativo.
class Tomo extends FormzInput<int, TomoError> {
  const Tomo.pure({this.esManga = false}) : super.pure(0);

  const Tomo.dirty(int value, {this.esManga = false}) : super.dirty(value);

  /// Si el producto es un manga, y por lo tanto el tomo es obligatorio.
  ///
  /// Lo decide el tipo elegido en el formulario, no el propio campo, así que
  /// quien construye la entrada tiene que pasarlo.
  final bool esManga;

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == TomoError.negativo) {
      return 'El tomo no puede ser negativo';
    }
    if (displayError == TomoError.faltante) {
      return 'Un manga necesita su número de tomo, desde el 1';
    }

    return null;
  }

  @override
  TomoError? validator(int value) {
    if (value < 0) return TomoError.negativo;
    if (esManga && value < 1) return TomoError.faltante;

    return null;
  }
}
