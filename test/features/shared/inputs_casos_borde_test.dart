// Casos borde y atípicos de los validadores de formulario.
//
// Estaban cubiertos solo de refilón, a través de las pruebas del formulario de
// registro y de la pantalla de producto. Aquí se prueban directamente, porque
// son las reglas que deciden si alguien puede entrar o publicar.
//
// Varias de estas pruebas **fijan limitaciones conocidas, no ideales**. Se
// escriben igual, y se explica por qué: una limitación documentada es una
// decisión; una limitación que nadie anotó es una sorpresa esperando a que un
// usuario con un correo poco común no pueda registrarse.
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/inputs/inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email', () {
    test('en estado inicial no muestra error', () {
      const campo = Email.pure();
      expect(campo.errorMessage, isNull);
      expect(campo.isPure, isTrue);
    });

    test('acepta las formas corrientes', () {
      for (final valor in [
        'usuario1@mundo-otaku.demo',
        'marco@gmail.com',
        'a@b.co',
        'con.punto@dominio.cl',
        'con-guion@sub.dominio.cl',
        'MAYUSCULAS@DOMINIO.COM',
        'con_guion_bajo@dominio.org',
        'numeros123@dominio456.net',
      ]) {
        expect(
          Email.dirty(valor).isValid,
          isTrue,
          reason: '"$valor" debería aceptarse',
        );
      }
    });

    test('rechaza lo que no es un correo', () {
      for (final valor in [
        'sin-arroba.cl',
        '@sin-parte-local.cl',
        'sin-dominio@',
        'sin-punto@dominio',
        'dos@@arrobas.cl',
        'espacio en@medio.cl',
      ]) {
        final campo = Email.dirty(valor);
        expect(campo.isValid, isFalse, reason: '"$valor" debería rechazarse');
        expect(campo.errorMessage, 'No tiene formato de correo electrónico');
      }
    });

    test('vacío y solo espacios dan el error de campo requerido, no el de '
        'formato', () {
      for (final valor in ['', '   ', '\n', '\t']) {
        expect(Email.dirty(valor).errorMessage, 'El campo es requerido');
      }
    });

    test('LIMITACIÓN: los espacios alrededor no se recortan', () {
      // El validador recorta para decidir si está vacío, pero la expresión
      // regular corre sobre el valor **sin recortar**. Un correo copiado y
      // pegado con un espacio al final se rechaza por formato, y el mensaje no
      // ayuda a entender por qué. Vale la pena saberlo antes de que un usuario
      // lo reporte como "la app no me deja entrar".
      expect(const Email.dirty(' marco@gmail.com').isValid, isFalse);
      expect(const Email.dirty('marco@gmail.com ').isValid, isFalse);
      expect(const Email.dirty('marco@gmail.com').isValid, isTrue);
    });

    test('LIMITACIÓN: el dominio de primer nivel solo admite de 2 a 4 letras',
        () {
      // La expresión regular termina en `[\w-]{2,4}`. Los dominios largos
      // existen y son válidos: quien tenga uno no puede registrarse.
      expect(const Email.dirty('marco@dominio.com').isValid, isTrue);
      expect(const Email.dirty('marco@dominio.info').isValid, isTrue);
      expect(const Email.dirty('marco@dominio.museum').isValid, isFalse);
      expect(const Email.dirty('marco@dominio.online').isValid, isFalse);
      // Y uno de una sola letra tampoco pasa, que sí es correcto.
      expect(const Email.dirty('marco@dominio.c').isValid, isFalse);
    });

    test('LIMITACIÓN: no admite las direcciones con etiqueta (usuario+etiqueta)',
        () {
      // Gmail y otros permiten `marco+compras@gmail.com`. El `+` no está en el
      // juego de caracteres aceptado, así que se rechaza.
      expect(const Email.dirty('marco+compras@gmail.com').isValid, isFalse);
    });

    test('LIMITACIÓN: acepta puntos consecutivos, que no son válidos', () {
      // Al revés que las anteriores: esta es permisiva de más. No deja entrar a
      // nadie que no deba, porque el servidor valida aparte, pero explica por
      // qué un correo mal escrito llega hasta la API.
      expect(const Email.dirty('marco..avaria@gmail.com').isValid, isTrue);
    });
  });

  group('Password', () {
    test('en estado inicial no muestra error', () {
      expect(const Password.pure().errorMessage, isNull);
    });

    test('el mínimo son seis caracteres, y seis bastan', () {
      expect(const Password.dirty('12345').isValid, isFalse);
      expect(const Password.dirty('12345').errorMessage, 'Mínimo 6 caracteres');
      expect(const Password.dirty('123456').isValid, isTrue);
      expect(const Password.dirty('MundoOtakuDemo1!').isValid, isTrue);
    });

    test('solo espacios se trata como vacío, no como demasiado corta', () {
      // El orden de las comprobaciones importa: si se midiera el largo primero,
      // seis espacios pasarían como contraseña válida.
      expect(const Password.dirty('      ').errorMessage, 'El campo es requerido');
      expect(const Password.dirty('').errorMessage, 'El campo es requerido');
    });

    test('LIMITACIÓN: los espacios cuentan para el largo mínimo', () {
      // "  1234" tiene seis caracteres y algo que no es espacio, así que pasa.
      // No es un agujero grave —la API también la aceptaría— pero conviene que
      // esté escrito y no se descubra al depurar un acceso que falla.
      expect(const Password.dirty('  1234').isValid, isTrue);
      expect(const Password.dirty('  123').isValid, isFalse);
    });

    test('acepta caracteres no latinos y símbolos', () {
      for (final valor in ['контрасeña', '交換パスワード', 'ñandú!', '🔐🔐🔐🔐🔐🔐']) {
        expect(
          Password.dirty(valor).isValid,
          isTrue,
          reason: '"$valor" tiene seis o más caracteres',
        );
      }
    });
  });

  group('Tomo', () {
    // Un tomo es el número de volumen de un manga o manhwa, igual que el de un
    // libro: el mínimo es 1, porque no existe el tomo cero. Pero el catálogo
    // tiene además Ropa, Taza y Otros, donde el tomo no significa nada y el 0
    // quiere decir "no aplica" —las fichas ocultan la etiqueta con
    // `if (product.tomo > 0)`—. Por eso la obligación depende del tipo.

    test('el estado inicial es cero y no muestra error', () {
      const campo = Tomo.pure();
      expect(campo.value, 0);
      expect(campo.errorMessage, isNull);
    });

    test('un manga sin tomo no es válido', () {
      const campo = Tomo.dirty(0, esManga: true);
      expect(campo.isValid, isFalse);
      expect(campo.errorMessage, 'Un manga necesita su número de tomo, desde el 1');
    });

    test('un manga acepta desde el 1 en adelante', () {
      for (final valor in [1, 2, 23, 9999]) {
        expect(
          const Tomo.pure(esManga: true).validator(valor),
          isNull,
          reason: 'el tomo $valor de un manga debería aceptarse',
        );
      }
    });

    test('lo que no es manga puede quedarse en cero, sin error', () {
      // Una taza o una polera no tienen volumen. Obligarlas a declarar
      // "Tomo 1" haría aparecer esa etiqueta en su ficha, mintiendo.
      const campo = Tomo.dirty(0);
      expect(campo.isValid, isTrue);
      expect(campo.errorMessage, isNull);
    });

    test('lo que no es manga también puede llevar un número, si tiene sentido',
        () {
      // Una novela ligera publicada como "Otros" sí tiene volumen.
      expect(const Tomo.dirty(3).isValid, isTrue);
    });

    test('ningún tipo admite tomos negativos', () {
      for (final valor in [-1, -2, -9999]) {
        for (final esManga in [true, false]) {
          final campo = Tomo.dirty(valor, esManga: esManga);
          expect(
            campo.isValid,
            isFalse,
            reason: 'tomo $valor con esManga=$esManga',
          );
          expect(campo.errorMessage, 'El tomo no puede ser negativo');
        }
      }
    });

    test('el -1 ya no choca con un valor centinela', () {
      // Antes el validador usaba `int.tryParse(value.toString()) ?? -1` y
      // comprobaba `== -1` para detectar un valor no numérico. El campo ya era
      // un `int`, así que esa rama era inalcanzable, y el -1 legítimo chocaba
      // con el centinela: se reportaba como "No tiene formato de número". La
      // comprobación se retiró; ahora -1 y -2 dan el mismo mensaje, que es el
      // correcto.
      expect(
        const Tomo.dirty(-1).errorMessage,
        const Tomo.dirty(-2).errorMessage,
      );
      expect(const Tomo.dirty(-1).errorMessage, 'El tomo no puede ser negativo');
    });
  });

  group('Fullname y Title', () {
    test('exigen algo más que espacios', () {
      for (final valor in ['', '   ', '\n\t']) {
        expect(Fullname.dirty(valor).isValid, isFalse, reason: '"$valor"');
        expect(Title.dirty(valor).isValid, isFalse, reason: '"$valor"');
      }
    });

    test('aceptan nombres reales, con acentos y varias palabras', () {
      for (final valor in [
        'Marco Avaria',
        'José Ñuñez',
        'Komi-san Volumen 23',
        '交換',
        'a',
      ]) {
        expect(Fullname.dirty(valor).isValid, isTrue, reason: '"$valor"');
        expect(Title.dirty(valor).isValid, isTrue, reason: '"$valor"');
      }
    });

    test('no imponen un largo máximo', () {
      // Se fija a propósito: si algún día hace falta un tope, que sea una
      // decisión y no una sorpresa de la base de datos.
      final muyLargo = 'a' * 5000;
      expect(Fullname.dirty(muyLargo).isValid, isTrue);
      expect(Title.dirty(muyLargo).isValid, isTrue);
    });
  });
}
