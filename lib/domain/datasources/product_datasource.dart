import '../entities/product.dart';

abstract class ProductDatasource {

  Future<List<Product>> getProductByPage({ int page = 1 });
}