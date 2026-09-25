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
    // Casos contrastados con `isEmail` de validator.js 13.15.35, que es lo que
    // usa la API por debajo de `@IsEmail()`. El veredicto de cada fila **no se
    // escribió a mano**: se obtuvo ejecutando validator.js sobre la misma
    // lista. Si algún día la API y el formulario discrepan, esta tabla falla.
    const segunLaApi = <(String, bool)>[
      ('usuario1@mundo-otaku.demo', true),
      ('marco@gmail.com', true),
      ('a@b.co', true),
      ('Marco.Avaria@Gmail.COM', true),
      ('marco+compras@gmail.com', true),
      ('con_guion_bajo@dominio.org', true),
      ('numeros123@dominio456.net', true),
      ('o\'brien@dominio.cl', true),
      ('x!#\$%&*=?^{|}~@dominio.cl', true),
      ('marco@sub.dominio.co.uk', true),
      ('marco@dominio.museum', true),
      ('marco@dominio.online', true),
      ('marco@dominio.photography', true),
      ('jos\u{E9}@dominio.cl', true),
      ('marco@m\u{FC}nchen.de', true),
      ('marco@xn--mnchen-3ya.de', true),
      ('\u{F1}and\u{FA}@dominio.cl', true),
      ('sin-arroba.cl', false),
      ('@sin-parte-local.cl', false),
      ('sin-dominio@', false),
      ('sin-punto@dominio', false),
      ('dos@@arrobas.cl', false),
      ('a@b@c.cl', false),
      ('espacio en@medio.cl', false),
      ('marco..avaria@gmail.com', false),
      ('.marco@gmail.com', false),
      ('marco.@gmail.com', false),
      ('marco@localhost', false),
      ('marco@-dominio.com', false),
      ('marco@dominio-.com', false),
      ('marco@dominio..com', false),
      ('marco@.dominio.com', false),
      ('marco@dominio.c', false),
      ('marco@dominio.123', false),
      ('marco@dominio_x.cl', false),
      ('marco@[127.0.0.1]', false),
      ('marco@127.0.0.1', false),
      ('marco@\u{FF44}\u{FF4F}\u{FF4D}\u{FF49}\u{FF4E}\u{FF49}\u{FF4F}.com', false),
      ('marco@dominio.com.', false),
      ('\u{1F600}@dominio.cl', false),
      ('marco@dominio.\u{1F600}', false),
      ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@x.com', true),
      ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@x.com', false),
      ('marco@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com', true),
      ('marco@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com', false),
      ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com', false),
      ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.co', false),
      ('\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}@x.com', true),
      ('\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}\u{E9}@x.com', false),
    ];

    test('acepta y rechaza exactamente lo mismo que la API', () {
      for (final (correo, valido) in segunLaApi) {
        expect(
          Email.dirty(correo).isValid,
          valido,
          reason: 'validator.js dice ${valido ? "válido" : "inválido"}: $correo',
        );
      }
    });

    test('diferencia deliberada: sin partes locales entre comillas', () {
      // validator.js las acepta; aquí se rechazan a propósito (ver `Email`).
      expect(const Email.dirty('"marco avaria"@gmail.com').isValid, isFalse);
    });

    test('diferencia deliberada: sin espacios Unicode dentro del dominio', () {
      expect(const Email.dirty('marco@do\u2003minio.cl').isValid, isFalse);
    });

    test('en estado inicial no muestra error', () {
      const campo = Email.pure();
      expect(campo.errorMessage, isNull);
      expect(campo.isPure, isTrue);
    });

    test('vacío o solo espacios da "campo requerido", no el de formato', () {
      for (final valor in ['', '   ', '\n', '\t']) {
        expect(Email.dirty(valor).errorMessage, 'El campo es requerido');
      }
    });

    test('un correo mal formado da el mensaje de formato', () {
      expect(
        const Email.dirty('marco..avaria@gmail.com').errorMessage,
        'No tiene formato de correo electrónico',
      );
    });

    test('los espacios alrededor no invalidan el correo', () {
      // Antes se rechazaba un correo pegado con un espacio al final, con un
      // mensaje que no explicaba por qué.
      expect(const Email.dirty(' marco@gmail.com').isValid, isTrue);
      expect(const Email.dirty('marco@gmail.com  ').isValid, isTrue);
    });

    test('se envía sin espacios y en minúsculas, como lo guarda la API', () {
      expect(
        const Email.dirty('  Marco.Avaria@Gmail.COM ').normalizado,
        'marco.avaria@gmail.com',
      );
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
    // El tomo es el número de volumen de un manga o manhwa, y **el tomo 0
    // existe**: hay obras que, ya avanzada la serie, publican un tomo 0 con una
    // historia previa a la principal. La entrada guarda el texto escrito para
    // distinguir "0" de "vacío", que con un entero eran lo mismo.

    test('el estado inicial está vacío y no muestra error', () {
      const campo = Tomo.pure();
      expect(campo.value, '');
      expect(campo.numero, isNull);
      expect(campo.errorMessage, isNull);
    });

    test('el tomo 0 de un manga es válido', () {
      const campo = Tomo.dirty('0', esManga: true);
      expect(campo.isValid, isTrue);
      expect(campo.numero, 0);
      expect(campo.errorMessage, isNull);
    });

    test('un manga acepta cualquier número desde el 0', () {
      for (final texto in ['0', '1', '23', '999', '2147483647']) {
        expect(
          Tomo.dirty(texto, esManga: true).isValid,
          isTrue,
          reason: 'el tomo "$texto" de un manga debería aceptarse',
        );
      }
    });

    test('un manga con el campo vacío no es válido', () {
      for (final texto in ['', '   ']) {
        final campo = Tomo.dirty(texto, esManga: true);
        expect(campo.isValid, isFalse, reason: '"$texto"');
        expect(
          campo.errorMessage,
          'Un manga necesita su número de tomo (puede ser 0)',
        );
      }
    });

    test('lo que no es manga puede quedar vacío, sin error', () {
      // Una taza o una polera no tienen volumen; al guardarse queda en 0,
      // que para ellos significa "no aplica".
      const campo = Tomo.dirty('');
      expect(campo.isValid, isTrue);
      expect(campo.numero, isNull);
    });

    test('lo que no es manga también puede llevar un número', () {
      // Una novela ligera publicada como "Otros" sí tiene volumen.
      expect(const Tomo.dirty('3').isValid, isTrue);
      expect(const Tomo.dirty('0').isValid, isTrue);
    });

    test('los espacios alrededor no importan', () {
      expect(const Tomo.dirty(' 12 ', esManga: true).isValid, isTrue);
      expect(const Tomo.dirty(' 12 ', esManga: true).numero, 12);
    });

    test('ningún tipo admite tomos negativos', () {
      for (final texto in ['-1', '-2', '-9999']) {
        for (final esManga in [true, false]) {
          final campo = Tomo.dirty(texto, esManga: esManga);
          expect(campo.isValid, isFalse, reason: '"$texto" esManga=$esManga');
          expect(campo.errorMessage, 'El tomo no puede ser negativo');
        }
      }
    });

    test('lo que no es un número entero se rechaza con su propio mensaje', () {
      // Antes el campo convertía todo lo ilegible en -1, y el mensaje decía
      // "no puede ser negativo" aunque nadie hubiera escrito un signo menos.
      for (final texto in ['1.5', 'abc', '3a', '1,5', '½', '٣']) {
        for (final esManga in [true, false]) {
          final campo = Tomo.dirty(texto, esManga: esManga);
          expect(campo.isValid, isFalse, reason: '"$texto" esManga=$esManga');
          expect(campo.errorMessage, 'Escribe solo el número del tomo');
        }
      }
    });

    test('un número que no cabe en la base se rechaza antes de enviarlo', () {
      // La columna `tomo` es un `int` de PostgreSQL: 2147483647 como máximo.
      expect(const Tomo.dirty('2147483647').isValid, isTrue);
      for (final texto in ['2147483648', '99999999999999999999999']) {
        final campo = Tomo.dirty(texto, esManga: true);
        expect(campo.isValid, isFalse, reason: texto);
        expect(campo.errorMessage, 'Ese número de tomo es demasiado grande');
      }
      // Y uno negativo enorme sigue siendo, ante todo, negativo.
      expect(
        const Tomo.dirty('-99999999999999999999999').errorMessage,
        'El tomo no puede ser negativo',
      );
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
