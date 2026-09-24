// El tomo es obligatorio solo cuando el producto es un manga, y el formulario
// tiene que seguir esa regla **mientras** se edita, no solo al enviar.
//
// Este archivo nace de dos cosas del 2026-09-24. La primera, la regla de
// dominio que fijó Marco: un tomo es el número de volumen de un manga o
// manhwa, así que el mínimo es 1. La segunda, un desfase de validación que
// apareció al implementarla y que hasta entonces no se notaba.
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/forms/product_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Product _producto({
  String typeOf = 'Otros',
  int tomo = 0,
  String title = 'Un producto',
}) {
  return Product(
    id: 'new',
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
  group('un manga necesita su tomo', () {
    test('un manga sin tomo no deja enviar el formulario', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 0));
      form.onTitleChanged('Komi-san Volumen 23');

      expect(form.state.isFormValid, isFalse);
      expect(form.state.tomo.errorMessage, isNotNull);
    });

    test('con el tomo puesto, sí deja enviar', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 0));
      form.onTitleChanged('Komi-san Volumen 23');
      form.onStockChanged(23);

      expect(form.state.isFormValid, isTrue);
      expect(form.state.tomo.errorMessage, isNull);
    });

    test('un manga que ya venía con tomo se abre válido para editar', () {
      // Los 8 productos publicados son manga y todos tienen tomo 1 o mayor:
      // ninguno debe quedar bloqueado al abrirlo.
      final form = _formulario(
        _producto(typeOf: 'Manga', tomo: 23, title: 'Komi-san Volumen 23'),
      );
      form.onTitleChanged('Komi-san Volumen 23');

      expect(form.state.isFormValid, isTrue);
    });
  });

  group('lo que no es manga no necesita tomo', () {
    for (final tipo in ['Ropa', 'Taza', 'Otros']) {
      test('$tipo se puede publicar sin tomo', () {
        final form = _formulario(_producto(typeOf: tipo, tomo: 0));
        form.onTitleChanged('Una polera');

        expect(form.state.isFormValid, isTrue);
        expect(form.state.tomo.errorMessage, isNull);
      });
    }

    test('ningún tipo admite un tomo negativo', () {
      for (final tipo in ['Ropa', 'Taza', 'Otros', 'Manga']) {
        final form = _formulario(_producto(typeOf: tipo));
        form.onTitleChanged('Algo');
        form.onStockChanged(-1);

        expect(form.state.isFormValid, isFalse, reason: 'tipo $tipo');
      }
    });
  });

  group('cambiar de tipo cambia la regla en el momento', () {
    test('pasar a Manga vuelve obligatorio el tomo que estaba en cero', () {
      final form = _formulario(_producto(typeOf: 'Otros', tomo: 0));
      form.onTitleChanged('Algo');
      expect(form.state.isFormValid, isTrue);

      form.onTypeChanged('Manga');

      expect(
        form.state.isFormValid,
        isFalse,
        reason: 'si el tipo cambia pero la entrada del tomo conserva la regla '
            'anterior, el formulario se deja enviar sin tomo',
      );
      expect(form.state.tomo.errorMessage, isNotNull);
    });

    test('salir de Manga libera el tomo en cero', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 0));
      form.onTitleChanged('Algo');
      expect(form.state.isFormValid, isFalse);

      form.onTypeChanged('Taza');

      expect(form.state.isFormValid, isTrue);
      expect(form.state.tomo.errorMessage, isNull);
    });
  });

  group('la validez no va una edición atrasada', () {
    // El defecto real que se corrigió: `onStockChanged` validaba con
    // `state.tomo.value`, que en ese punto todavía es el valor **anterior**,
    // porque `state` no se ha reasignado cuando se evalúan los argumentos de
    // `copyWith`. Con el tomo opcional no se notaba; con el tomo obligatorio,
    // escribir el número correcto no habría desbloqueado el formulario.
    test('escribir el tomo correcto lo desbloquea en la misma edición', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 0));
      form.onTitleChanged('Komi-san');
      expect(form.state.isFormValid, isFalse);

      form.onStockChanged(23);

      expect(
        form.state.isFormValid,
        isTrue,
        reason: 'hizo falta una segunda edición para que la validez se pusiera '
            'al día: se está validando con el valor anterior',
      );
    });

    test('borrar el tomo lo vuelve a bloquear en la misma edición', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 23));
      form.onTitleChanged('Komi-san');
      expect(form.state.isFormValid, isTrue);

      form.onStockChanged(0);

      expect(form.state.isFormValid, isFalse);
    });

    test('el valor guardado es el último escrito, no el anterior', () {
      final form = _formulario(_producto(typeOf: 'Manga', tomo: 1));
      form.onStockChanged(7);
      form.onStockChanged(9);

      expect(form.state.tomo.value, 9);
    });
  });

  test('enviar un manga sin tomo no llama a la API', () async {
    var llamadas = 0;
    final form = ProductFormNotifier(
      product: _producto(typeOf: 'Manga', tomo: 0),
      onSubmitCallback: (_) async {
        llamadas++;
        return true;
      },
    );
    form.onTitleChanged('Komi-san');

    expect(await form.onFormSubmit(), isFalse);
    expect(llamadas, 0, reason: 'no debe salir una petición que se sabe mala');
  });
}
