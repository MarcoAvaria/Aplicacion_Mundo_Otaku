import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/products_provider.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';

final productFormProvider = StateNotifierProvider.autoDispose
    .family<ProductFormNotifier, ProductFormState, Product>((ref, product) {
  final createUpdateCallback =
      ref.watch(productsProvider.notifier).createOrUpdateProduct;

  return ProductFormNotifier(
    product: product,
    onSubmitCallback: createUpdateCallback,
  );
});

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final Future<bool> Function(Map<String, dynamic> productLike)?
      onSubmitCallback;

  ProductFormNotifier({
    this.onSubmitCallback,
    required Product product,
  }) : super(ProductFormState(
          id: product.id,
          title: Title.dirty(product.title),
          typeOf: product.typeOf,
          tomo: _tomoPara(product.tomo, product.typeOf),
          sizeOf: product.sizeOf,
          gender: product.gender,
          demographic: product.demographic,
          description: product.description,
          tags: product.tags.join(', '),
          images: product.images,
        ));

  Future<bool> onFormSubmit() async {
    _touchedEverything();
    if (!state.isFormValid) return false;

    if (onSubmitCallback == null) return false;

    final productLike = {
      'id': (state.id == 'new') ? null : state.id,
      'title': state.title.value,
      //'price': state.price.value,
      'description': state.description,
      'typeOf': state.typeOf,
      'tomo': state.tomo.value,
      'sizeOf': state.sizeOf,
      'gender': state.gender,
      'demographic': state.demographic,
      'tags': state.tags.split(','),
      'images': state.images
          .map((image) => image.replaceAll(
                '${Environment.apiUrl}${ApiEndpoints.productImages}/',
                '',
              ))
          .toList()
    };

    try {
      return await onSubmitCallback!(productLike);
    } catch (e) {
      return false;
    }
  }

  void _touchedEverything() {
    state = state.copyWith(
      isFormValid: _esValido(
        state.title.value,
        state.tomo.value,
        state.typeOf,
      ),
    );
  }

  void updateProductImage(String path) {
    state = state.copyWith(images: [...state.images, path]);
  }

  void onTitleChanged(String value) {
    state = state.copyWith(
      title: Title.dirty(value),
      isFormValid: _esValido(value, state.tomo.value, state.typeOf),
    );
  }

  void onTypeChanged(String typeOf) {
    // Cambiar de tipo cambia la regla del tomo: pasar a Manga lo vuelve
    // obligatorio, y salir de Manga lo libera. Si aquí solo se guardara el
    // tipo, la entrada del tomo conservaría la regla anterior y el formulario
    // quedaría bloqueado —o desbloqueado— por el motivo equivocado.
    state = state.copyWith(
      typeOf: typeOf,
      tomo: _tomoPara(state.tomo.value, typeOf),
      isFormValid: _esValido(state.title.value, state.tomo.value, typeOf),
    );
  }

  void onStockChanged(int value) {
    // Antes validaba con `state.tomo.value`, que aquí todavía es el valor
    // **anterior**: `state` no se ha reasignado cuando se evalúan los
    // argumentos de `copyWith`. La validez iba una edición atrasada. No se
    // notaba mientras el 0 era válido; con el tomo obligatorio sí se nota,
    // porque escribir un tomo correcto no habría desbloqueado el formulario.
    state = state.copyWith(
      tomo: _tomoPara(value, state.typeOf),
      isFormValid: _esValido(state.title.value, value, state.typeOf),
    );
  }

  void onSizeChanged(String sizeOf) {
    state = state.copyWith(sizeOf: sizeOf);
  }

  void onGenderChanged(String gender) {
    state = state.copyWith(gender: gender);
  }

  void onDemographicChanged(String demographic) {
    state = state.copyWith(demographic: demographic);
  }

  void onDescriptionChanged(String description) {
    state = state.copyWith(description: description);
  }

  void onTagsChanged(String tags) {
    state = state.copyWith(tags: tags);
  }

  /// El tomo solo es obligatorio cuando el producto es un manga.
  ///
  /// Para Ropa, Taza y Otros el tomo no significa nada y el 0 quiere decir
  /// "no aplica": las fichas ocultan la etiqueta con `if (product.tomo > 0)`.
  static Tomo _tomoPara(int valor, String typeOf) =>
      Tomo.dirty(valor, esManga: typeOf == 'Manga');

  static bool _esValido(String titulo, int tomo, String typeOf) =>
      Formz.validate([Title.dirty(titulo), _tomoPara(tomo, typeOf)]);
}

class ProductFormState {
  final bool isFormValid;
  final String? id;
  final Title title;
  //final Price price;
  final String typeOf;
  final String sizeOf;
  final String gender;
  final String demographic;
  final Tomo tomo;
  //final Tomo? inStock;
  final String description;
  final String tags;
  final List<String> images;

  ProductFormState({
    this.isFormValid = false,
    this.id,
    this.title = const Title.dirty(''),
    //this.price = const Price.dirty(0),
    this.typeOf = 'Otros',
    this.sizeOf = 'Ninguno',
    this.gender = 'Ninguno',
    this.demographic = 'Shonen',
    //this.tomo = const Tomo.dirty(0),
    this.tomo = const Tomo.dirty(0),
    this.description = '',
    this.tags = '',
    this.images = const [],
  });

  ProductFormState copyWith({
    bool? isFormValid,
    String? id,
    Title? title,
    String? typeOf,
    //Price? price,
    String? sizeOf,
    String? gender,
    String? demographic,
    Tomo? tomo,
    String? description,
    String? tags,
    List<String>? images,
  }) =>
      ProductFormState(
        isFormValid: isFormValid ?? this.isFormValid,
        id: id ?? this.id,
        title: title ?? this.title,
        typeOf: typeOf ?? this.typeOf,
        //price: price ?? this.price,
        sizeOf: sizeOf ?? this.sizeOf,
        gender: gender ?? this.gender,
        demographic: demographic ?? this.demographic,
        tomo: tomo ?? this.tomo,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        images: images ?? this.images,
      );
}
