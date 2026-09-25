import 'package:flutter_riverpod/legacy.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';

import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';

final productProvider = StateNotifierProvider.autoDispose
    .family<ProductNotifier, ProductState, String>((ref, productId) {
  final productsRepository = ref.watch(productsRepositoryProvider);

  return ProductNotifier(
      productsRepository: productsRepository, productId: productId);
});

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductsRepository productsRepository;

  ProductNotifier({
    required this.productsRepository,
    required String productId,
    bool loadOnCreate = true,
  }) : super(ProductState(id: productId)) {
    if (loadOnCreate) loadProduct();
  }

  Product newEmptyProduct() {
    return Product(
      id: 'new',
      title: '',
      typeOf: 'Otros',
      description: '',
      tomo: 0,
      sizeOf: 'Ninguno',
      //gender: 'shonen',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: [],
      images: [],
    );
  }

  Future<void> loadProduct() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      if (state.id == 'new') {
        state = state.copyWith(
          isLoading: false,
          product: newEmptyProduct(),
        );
        return;
      }

      final product = await productsRepository.getProductById(state.id);
      state = state.copyWith(isLoading: false, product: product);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No fue posible cargar el producto.',
      );
    }
  }

  Future<bool> deleteProduct() async {
    if (state.id == 'new') return false;
    try {
      await productsRepository.deleteProduct(state.id);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ProductState {
  final String id;
  final Product? product;
  final bool isLoading;
  final bool isSaving;
  final String errorMessage;

  ProductState({
    required this.id,
    this.product,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage = '',
  });

  ProductState copyWith({
    String? id,
    Product? product,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) =>
      ProductState(
        id: id ?? this.id,
        product: product ?? this.product,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
