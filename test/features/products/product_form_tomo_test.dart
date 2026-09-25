// El tomo en el formulario de producto.
//
// Reglas, fijadas por Marco el 2026-09-24:
// - el tomo es el número de volumen de un manga o manhwa;
// - **el tomo 0 existe** (precuelas que salen ya avanzada la serie);
// - es obligatorio solo si el producto es un manga;
// - nunca es negativo.
//
// El formulario guarda el texto escrito, para distinguir "0" de "vacío".
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/forms/product_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Product _producto({
  String id = 'new',
  String typeOf = 'Otros',
  int tomo = 0,
  String title = 'Un producto',
}) {
  return Product(
    id: id,
    title: title,
    typeOf: typeOf,
    description: 'descripción',
    tomo: tomo,
    sizeOf: 'Ninguno',
    gender: 'Ninguno',
    demographic: 'Shonen',
    tags: const [],
    images: const [],
  );
}

ProductFormNotifier _formulario(Product producto) =>
    ProductFormNotifier(product: producto);

void main() {
  group('un producto nuevo', () {
    test('arranca con el tomo vacío, no en 0', () {
      // Si arrancara en 0, un manga se podría publicar sin que nadie haya
      // escrito su tomo, y quedaría como "Tomo 0", que es un tomo real.
      final form = _formulario(_producto(typeOf: 'Manga'));
      expect(form.state.tomo.value, '');
    });

    test('un manga nuevo no deja enviar hasta que se escribe el tomo', () {
      final form = _formulario(_producto(typeOf: 'Manga'));
      form.onTitleChanged('Komi-san');

      expect(form.state.isFormValid, isFalse);
      expect(form.state.tomo.errorMessage, isNotNull);
    });
  });

  group('el tomo 0 de un manga', () {
    test('se puede publicar', () {
      final form = _formulario(_producto(typeOf: 'Manga'));
      form.onTitleChanged('Kimetsu no Yaiba Volumen 0');
      form.onStockChanged('0');

      expect(form.state.isFormValid, isTrue);
      expect(form.state.tomo.errorMessage, isNull);
    });

    test('se envía como 0 a la API', () async {
      Map<String, dynamic>? enviado;
      final form = ProductFormNotifier(
        product: _producto(typeOf: 'Manga'),
        onSubmitCallback: (datos) async {
          enviado = datos;
          return true;
        },
      );
      form.onTitleChanged('Kimetsu no Yaiba Volumen 0');
      form.onStockChanged('0');

      expect(await form.onFormSubmit(), isTrue);
      expect(enviado?['tomo'], 0);
    });

    test('un manga ya publicado con tomo 0 se abre válido para editar', () {
      final form = _formulario(
        _producto(id: 'abc', typeOf: 'Manga', tomo: 0, title: 'Precuela'),
      );
      form.onTitleChanged('Precuela');

      expect(form.state.tomo.value, '0');
      expect(form.state.isFormValid, isTrue);
    });
  });

  group('un manga ya publicado', () {
    test('se abre con su número y válido', () {
      // Los 8 productos del catálogo son manga con tomo 1 o mayor.
      final form = _formulario(
        _producto(id: 'abc', typeOf: 'Manga', tomo: 23, title: 'Komi-san'),
      );
      form.onTitleChanged('Komi-san');

      expect(form.state.tomo.value, '23');
      expect(form.state.isFormValid, isTrue);
    });

    test('borrar el tomo lo bloquea en la misma edición', () {
      final form = _formulario(
        _producto(id: 'abc', typeOf: 'Manga', tomo: 23, title: 'Komi-san'),
      );
      form.onTitleChanged('Komi-san');
      form.onStockChanged('');

      expect(form.state.isFormValid, isFalse);
    });
  });

  group('lo que no es manga', () {
    for (final tipo in ['Ropa', 'Taza', 'Otros']) {
      test('$tipo se publica con el tomo vacío, y se envía 0', () async {
        Map<String, dynamic>? enviado;
        final form = ProductFormNotifier(
          product: _producto(typeOf: tipo),
          onSubmitCallback: (datos) async {
            enviado = datos;
            return true;
          },
        );
        form.onTitleChanged('Una polera');

        expect(form.state.isFormValid, isTrue);
        expect(await form.onFormSubmit(), isTrue);
        expect(enviado?['tomo'], 0, reason: '0 = "no aplica"');
      });
    }

    test('ningún tipo admite un tomo negativo ni un texto', () {
      for (final tipo in ['Ropa', 'Taza', 'Otros', 'Manga']) {
        for (final texto in ['-1', '1.5', 'abc']) {
          final form = _formulario(_producto(typeOf: tipo));
          form.onTitleChanged('Algo');
          form.onStockChanged(texto);

          expect(form.state.isFormValid, isFalse, reason: '$tipo, "$texto"');
        }
      }
    });
  });

  group('cambiar de tipo cambia la regla en el momento', () {
    test('pasar a Manga con el tomo vacío bloquea el formulario', () {
      final form = _formulario(_producto(typeOf: 'Otros'));
      form.onTitleChanged('Algo');
      expect(form.state.isFormValid, isTrue);

      form.onTypeChanged('Manga');

      expect(form.state.isFormValid, isFalse);
      expect(form.state.tomo.errorMessage, isNotNull);
    });

    test('pasar a Manga con el tomo en 0 lo deja válido', () {
      final form = _formulario(_producto(typeOf: 'Otros'));
      form.onTitleChanged('Algo');
      form.onStockChanged('0');

      form.onTypeChanged('Manga');

      expect(form.state.isFormValid, isTrue);
    });

    test('salir de Manga libera el tomo vacío', () {
      final form = _formulario(_producto(typeOf: 'Manga'));
      form.onTitleChanged('Algo');
      expect(form.state.isFormValid, isFalse);

      form.onTypeChanged('Taza');

      expect(form.state.isFormValid, isTrue);
      expect(form.state.tomo.errorMessage, isNull);
    });
  });

  group('la validez no va una edición atrasada', () {
    test('escribir el tomo lo desbloquea en la misma edición', () {
      final form = _formulario(_producto(typeOf: 'Manga'));
      form.onTitleChanged('Komi-san');
      expect(form.state.isFormValid, isFalse);

      form.onStockChanged('23');

      expect(form.state.isFormValid, isTrue);
    });

    test('el valor guardado es el último escrito, no el anterior', () {
      final form = _formulario(_producto(typeOf: 'Manga'));
      form.onStockChanged('7');
      form.onStockChanged('9');

      expect(form.state.tomo.value, '9');
      expect(form.state.tomo.numero, 9);
    });
  });

  test('enviar un manga sin tomo no llama a la API', () async {
    var llamadas = 0;
    final form = ProductFormNotifier(
      product: _producto(typeOf: 'Manga'),
      onSubmitCallback: (_) async {
        llamadas++;
        return true;
      },
    );
    form.onTitleChanged('Komi-san');

    expect(await form.onFormSubmit(), isFalse);
    expect(llamadas, 0, reason: 'no debe salir una petición que se sabe mala');
  });

  group('qué muestran las fichas', () {
    test('un manga muestra su tomo aunque sea 0', () {
      expect(_producto(typeOf: 'Manga', tomo: 0).muestraTomo, isTrue);
      expect(_producto(typeOf: 'Manga', tomo: 23).muestraTomo, isTrue);
    });

    test('lo demás oculta el 0, que para ellos es "no aplica"', () {
      for (final tipo in ['Ropa', 'Taza', 'Otros']) {
        expect(_producto(typeOf: tipo, tomo: 0).muestraTomo, isFalse,
            reason: tipo);
      }
      expect(_producto(typeOf: 'Otros', tomo: 3).muestraTomo, isTrue);
    });
  });
}
