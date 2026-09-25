import 'dart:convert';

import 'package:formz/formz.dart';

enum EmailError { empty, format }

/// Un correo electrónico, validado con la misma regla que la API.
///
/// La API usa `@IsEmail()` de class-validator, que por dentro es `isEmail` de
/// validator.js, la referencia práctica más extendida para validar correos
/// según los RFC 5321 y 5322. Este validador reproduce sus reglas por defecto
/// para que el formulario acepte y rechace **lo mismo que el servidor**: si
/// el cliente aceptara algo que la API rechaza, el usuario vería un error
/// peor y más tarde.
///
/// Lo que eso significa en la práctica:
/// - acepta etiquetas (`marco+compras@gmail.com`), dominios largos
///   (`.museum`, `.online`) y dominios con tildes o eñes;
/// - rechaza puntos consecutivos o en los bordes de la parte local, guiones
///   en los bordes de un dominio, dominios sin punto (`localhost`), IP y
///   dominios de primer nivel numéricos o de una sola letra;
/// - limita el correo completo a 254 caracteres, la parte local a 64 bytes y
///   el dominio a 254, como el RFC 5321;
/// - rechaza caracteres de ancho completo (`ａｂｃ`) en el dominio.
///
/// Dos diferencias deliberadas, las dos más estrictas que la API:
/// - la API acepta partes locales entre comillas (`"marco avaria"@gmail.com`).
///   Aquí se rechazan; son válidas en el papel pero casi nadie las usa, y
///   aceptarlas complicaría el formulario sin beneficio real;
/// - validator.js deja pasar espacios Unicode (como el espacio largo U+2003)
///   dentro de una etiqueta del dominio, porque caen en su rango
///   `¡-￿`. Aquí se rechazan: no existe un dominio real así.
///
/// Los espacios alrededor no cuentan: un correo pegado con un espacio al final
/// es válido, y al enviarse se manda [normalizado].
class Email extends FormzInput<String, EmailError> {
  const Email.pure() : super.pure('');

  const Email.dirty(String value) : super.dirty(value);

  /// Sin espacios alrededor y en minúsculas, que es como lo guarda la API.
  String get normalizado => value.trim().toLowerCase();

  String? get errorMessage {
    if (isValid || isPure) return null;

    if (displayError == EmailError.empty) return 'El campo es requerido';
    if (displayError == EmailError.format) {
      return 'No tiene formato de correo electrónico';
    }

    return null;
  }

  @override
  EmailError? validator(String value) {
    final correo = value.trim();
    if (correo.isEmpty) return EmailError.empty;
    if (!esValido(correo)) return EmailError.format;
    return null;
  }

  // Juegos de caracteres copiados de validator.js 13.15 (`isEmail` e
  // `isFQDN`). Los rangos Unicode excluyen a propósito los sustitutos, así que
  // los emoji quedan fuera, igual que allá.
  static final _parteLocal = RegExp(
    r"^[a-z\d!#\$%&'\*\+\-\/=\?\^_`{\|}~"
    '¡-퟿豈-﷏ﷰ-￯]+\$',
    caseSensitive: false,
  );
  static final _etiqueta = RegExp(
    '^[a-z¡-￿0-9-]+\$',
    caseSensitive: false,
  );
  static final _dominioDePrimerNivel = RegExp(
    '^([a-z¡-¨ª-퟿豈-﷏ﷰ-￯]{2,}'
    r'|xn[a-z0-9-]{2,})$',
    caseSensitive: false,
  );
  static final _anchoCompleto = RegExp('[！-～]');
  static final _espacios = RegExp(
    '[\\s -​  　﻿]',
  );

  /// Si [correo] (ya sin espacios alrededor) es una dirección válida.
  static bool esValido(String correo) {
    if (correo.length > 254) return false;

    final arroba = correo.lastIndexOf('@');
    if (arroba <= 0 || arroba == correo.length - 1) return false;

    final local = correo.substring(0, arroba);
    final dominio = correo.substring(arroba + 1);

    if (utf8.encode(local).length > 64) return false;
    if (utf8.encode(dominio).length > 254) return false;

    return _esParteLocalValida(local) && _esDominioValido(dominio);
  }

  static bool _esParteLocalValida(String local) {
    // Separada por puntos: ninguna parte vacía impide los puntos
    // consecutivos (`a..b`) y los de los bordes (`.a`, `a.`).
    return local.split('.').every(_parteLocal.hasMatch);
  }

  static bool _esDominioValido(String dominio) {
    if (_espacios.hasMatch(dominio)) return false;

    final etiquetas = dominio.split('.');
    // Exige al menos un punto: `marco@localhost` no es un correo público.
    if (etiquetas.length < 2) return false;

    final primerNivel = etiquetas.last;
    if (!_dominioDePrimerNivel.hasMatch(primerNivel)) return false;

    return etiquetas.every((etiqueta) =>
        etiqueta.isNotEmpty &&
        etiqueta.length <= 63 &&
        _etiqueta.hasMatch(etiqueta) &&
        !_anchoCompleto.hasMatch(etiqueta) &&
        !etiqueta.startsWith('-') &&
        !etiqueta.endsWith('-'));
  }
}
