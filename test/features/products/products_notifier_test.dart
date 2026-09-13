import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/products_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expone un fallo de carga y permite reintentar la misma página',
      () async {
    final repository = _ProductsRepository();
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    repository.failNextRequest = true;
    await notifier.loadNextPage();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.errorMessage, 'No fue posible cargar los productos.');
    expect(notifier.state.offset, 0);

    await notifier.loadNextPage();

    expect(notifier.state.errorMessage, isEmpty);
    expect(notifier.state.products.single.id, 'product-1');
    expect(notifier.state.offset, 10);
    expect(repository.requestedOffsets, [0, 0]);
  });

  test('marca el final sin avanzar el desplazamiento', () async {
    final repository = _ProductsRepository()..products = [];
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();

    expect(notifier.state.isLastPage, isTrue);
    expect(notifier.state.offset, 0);
  });
}

class _ProductsRepository implements ProductsRepository {
  bool failNextRequest = false;
  List<int> requestedOffsets = [];
  List<Product> products = [
    Product(
      id: 'product-1',
      title: 'Producto de prueba',
      typeOf: 'Manga',
      description: 'Descripción',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: const [],
      images: const [],
    ),
  ];

  @override
  Future<List<Product>> getProductsByPage(
      {int limit = 10, int offset = 0}) async {
    requestedOffsets.add(offset);
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('sin conexión');
    }
    return products;
  }

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> getProductById(String id) => throw UnimplementedError();

  @override
  Future<List<Product>> getProductsForCurrentUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<List<Product>> searchProductByTerm(String term) =>
      throw UnimplementedError();
}
