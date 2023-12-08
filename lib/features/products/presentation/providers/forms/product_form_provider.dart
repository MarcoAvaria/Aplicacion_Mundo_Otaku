import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/products_provider.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';

final productFormProvider = StateNotifierProvider.autoDispose.family<ProductFormNotifier, ProductFormState, Product>(
  (ref, product) {

    final createUpdateCallback = ref.watch( productsProvider.notifier ).createOrUpdateProduct;

    return ProductFormNotifier(
      product: product,
      onSubmitCallback: createUpdateCallback, 
    );
  }
);

class ProductFormNotifier extends StateNotifier<ProductFormState> { 

  final Future<bool> Function( Map<String,dynamic> productLike )? onSubmitCallback;

  ProductFormNotifier({
    this.onSubmitCallback,
    required Product product,
  }): super(
    ProductFormState(
      id: product.id,
      title: Title.dirty(product.title),
      typeOf: product.typeOf,
      tomo: Tomo.dirty(product.tomo),
      sizeOf: product.sizeOf,
      gender: product.gender,
      demographic: product.demographic,
      description: product.description,
      tags: product.tags.join(', '),
      images: product.images,      
    )
  );

  Future<bool> onFormSubmit() async { 
    _touchedEverything();
    if ( !state.isFormValid ) return false;
    
    if ( onSubmitCallback == null ) return false;

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
      'images': state.images.map(
        (image) => image.replaceAll('${ Environment.apiUrl }/files/product/',''))
        .toList()
    };

    try {
      return await onSubmitCallback!( productLike );
    } catch (e) {
      return false;
    }
  }


  void _touchedEverything() {
    state = state.copyWith(
      isFormValid: Formz.validate([
        Title.dirty(state.title.value),
        Tomo.dirty(state.tomo.value),
      ]),
    );
  }

  void updateProductImage( String path ) {
    state = state.copyWith(
      images: [...state.images, path ]
    );
  }

  void onTitleChanged( String value ){
    state = state.copyWith(
      title: Title.dirty(value),
      isFormValid: Formz.validate([
        Title.dirty(value),
        Tomo.dirty(state.tomo.value),
      ])
    );
  }

  void onTypeChanged( String typeOf ){
    state = state.copyWith(
      typeOf: typeOf
    );
  }
  
  void onStockChanged( int value ){
    state = state.copyWith(
      tomo: Tomo.dirty(value),
      isFormValid: Formz.validate([
        Title.dirty(state.title.value),
        Tomo.dirty(state.tomo.value),
      ])
    );
  }

  void onSizeChanged( String sizeOf ){
    state = state.copyWith(
      sizeOf: sizeOf
    );
  }

  void onGenderChanged( String gender ){
    state = state.copyWith(
      gender: gender
    );
  }

  void onDemographicChanged( String demographic ){
    state = state.copyWith(
      demographic: demographic
    );
  }

  void onDescriptionChanged( String description ){
    state = state.copyWith(
      description: description
    );
  }

  void onTagsChanged( String tags ){
    state = state.copyWith(
      tags: tags
    );
  }


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
  }) => ProductFormState(
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