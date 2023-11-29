import 'package:formz/formz.dart';

// Define input validation errors
enum TomoError { empty, value, format }
//enum TomoError { empty, value }

// Extend FormzInput and provide the input type and error type.
class Tomo extends FormzInput<int, TomoError> {

  // Call super.pure to represent an unmodified form input.
  const Tomo.pure() : super.pure(0);

  // Call super.dirty to represent a modified form input.
  const Tomo.dirty( int value ) : super.dirty(value);

  String? get errorMessage {
    if ( isValid || isPure ) return null;

    //if ( displayError == TomoError.empty ) return 'El campo es requerido';
    if ( displayError == TomoError.value ) return 'Número de ser igual o mayor a 0';
    if ( displayError == TomoError.format ) return 'No tiene formato de número';
    
    return null;
  }


  // Override validator to handle validating a given input value.
  @override
  TomoError? validator(int value) {

    if ( value.toString().isEmpty || value.toString().trim().isEmpty ) return TomoError.empty;
    //if ( value.toString().contains('..'))
    final isInteger = int.tryParse( value.toString()) ?? -1;
    if ( isInteger == -1 ) return TomoError.format;

    if ( value < 0 ) return TomoError.value;
    
    return null;
  }
}