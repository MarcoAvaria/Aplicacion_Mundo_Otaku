import 'dart:math' as math;

import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/products_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/product_provider.dart';
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

  test('permite reintentar la carga de un producto individual', () async {
    final repository = _ProductsRepository()..failNextProductLoad = true;
    final notifier = ProductNotifier(
      productsRepository: repository,
      productId: 'product-1',
      loadOnCreate: false,
    );

    await notifier.loadProduct();
    expect(notifier.state.errorMessage, 'No fue posible cargar el producto.');
    expect(notifier.state.product, isNull);

    await notifier.loadProduct();
    expect(notifier.state.errorMessage, isEmpty);
    expect(notifier.state.product?.id, 'product-1');
  });

  test('recargar reemplaza los productos en vez de acumularlos', () async {
    final repository = _ProductsRepository();
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();
    expect(notifier.state.products, hasLength(1));

    repository.products = [
      repository.products.first,
      _product('product-2'),
    ];
    await notifier.reloadLoadedPages();

    expect(notifier.state.products.map((p) => p.id), ['product-1', 'product-2']);
    expect(repository.requestedOffsets, [0, 0]);
  });

  test('recargar pide de una vez todo lo que ya estaba cargado', () async {
    final repository = _ProductsRepository()
      ..products = List.generate(25, (i) => _product('product-$i'));
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();
    await notifier.loadNextPage();
    expect(notifier.state.products, hasLength(20));

    await notifier.reloadLoadedPages();

    expect(repository.requestedLimits.last, 20);
    expect(repository.requestedOffsets.last, 0);
    expect(notifier.state.products, hasLength(20));
    expect(notifier.state.offset, 20);
    expect(notifier.state.isLastPage, isFalse);
  });

  test('recargar nunca pide menos de una página', () async {
    final repository = _ProductsRepository();
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();
    await notifier.reloadLoadedPages();

    expect(repository.requestedLimits.last, 10);
  });

  test('recargar sin nada cargado pide la primera página', () async {
    final repository = _ProductsRepository();
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.reloadLoadedPages();

    expect(repository.requestedLimits, [10]);
    expect(notifier.state.products, hasLength(1));
  });

  test('recargar funciona aunque la lista ya estuviera marcada como final',
      () async {
    final repository = _ProductsRepository()..products = [];
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();
    expect(notifier.state.isLastPage, isTrue);

    // `loadNextPage` se rendiría aquí; el refresco tiene que seguir sirviendo.
    repository.products = [_product('product-1')];
    await notifier.reloadLoadedPages();

    expect(notifier.state.products, hasLength(1));
    expect(notifier.state.errorMessage, isEmpty);
  });

  test('un fallo al recargar conserva lo que ya se veía', () async {
    final repository = _ProductsRepository();
    final notifier = ProductsNotifier(
      productsRepository: repository,
      loadOnCreate: false,
    );

    await notifier.loadNextPage();

    repository.failNextRequest = true;
    await notifier.reloadLoadedPages();

    expect(notifier.state.products, hasLength(1));
    expect(notifier.state.errorMessage, 'No fue posible cargar los productos.');
    expect(notifier.state.isLoading, isFalse);
  });
}

Product _product(String id) => Product(
      id: id,
      title: 'Producto $id',
      typeOf: 'Manga',
      description: 'Descripción',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: const [],
      images: const [],
    );

class _ProductsRepository implements ProductsRepository {
  bool failNextRequest = false;
  bool failNextProductLoad = false;
  List<int> requestedOffsets = [];
  List<int> requestedLimits = [];
  List<Product> products = [_product('product-1')];

  @override
  Future<List<Product>> getProductsByPage(
      {int limit = 10, int offset = 0}) async {
    requestedOffsets.add(offset);
    requestedLimits.add(limit);
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('sin conexión');
    }
    if (offset >= products.length) return [];
    return products.sublist(offset, math.min(offset + limit, products.length));
  }

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();

  @override
  Future<Product> getProductById(String id) async {
    if (failNextProductLoad) {
      failNextProductLoad = false;
      throw Exception('sin conexión');
    }
    return products.first;
  }

  @override
  Future<List<Product>> getProductsForCurrentUser(String userId) =>
      throw UnimplementedError();

  @override
  Future<List<Product>> searchProductByTerm(String term) =>
      throw UnimplementedError();
}
