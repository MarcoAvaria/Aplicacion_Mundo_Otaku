//import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final productsRepository = ref.watch(productsRepositoryProvider);

  return ProductsNotifier(productsRepository: productsRepository);
});

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductsRepository productsRepository;

  ProductsNotifier({
    required this.productsRepository,
    bool loadOnCreate = true,
  }) : super(ProductsState()) {
    if (loadOnCreate) loadNextPage();
  }

  Future<bool> createOrUpdateProduct(Map<String, dynamic> productLike) async {
    try {
      final product = await productsRepository.createUpdateProduct(productLike);

      final isProductInList =
          state.products.any((element) => element.id == product.id);

      if (!isProductInList) {
        state = state.copyWith(products: [...state.products, product]);
        return true;
      }

      state = state.copyWith(
          products: state.products
              .map(
                (element) => (element.id == product.id) ? product : element,
              )
              .toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future loadNextPage() async {
    if (state.isLoading || state.isLastPage) return;

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final products = await productsRepository.getProductsByPage(
          limit: state.limit, offset: state.offset);
      if (products.isEmpty) {
        state = state.copyWith(isLoading: false, isLastPage: true);
        return;
      }

      state = state.copyWith(
          isLastPage: false,
          isLoading: false,
          offset: state.offset + state.limit,
          products: [...state.products, ...products]);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No fue posible cargar los productos.',
      );
    }
  }

  List<Product> get userProducts => state.userProducts;
  bool get isLoading => state.isLoading;

  Future<void> loadUserProducts({String? userId}) async {
    if (userId == null || userId.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final products =
          await productsRepository.getProductsForCurrentUser(userId);
      state = state.copyWith(userProducts: products, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No fue posible cargar tus productos.',
      );
    }
  }
}

class ProductsState {
  final bool isLastPage;
  final int limit;
  final int offset;
  final bool isLoading;
  final List<Product> products;
  final List<Product> userProducts;
  final String errorMessage;

  ProductsState({
    this.isLastPage = false,
    this.limit = 10,
    this.offset = 0,
    this.isLoading = false,
    this.products = const [],
    this.userProducts = const [],
    this.errorMessage = '',
  });

  ProductsState copyWith({
    bool? isLastPage,
    int? limit,
    int? offset,
    bool? isLoading,
    List<Product>? products,
    List<Product>? userProducts,
    String? errorMessage,
  }) =>
      ProductsState(
        isLastPage: isLastPage ?? this.isLastPage,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        userProducts: userProducts ?? this.userProducts,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
