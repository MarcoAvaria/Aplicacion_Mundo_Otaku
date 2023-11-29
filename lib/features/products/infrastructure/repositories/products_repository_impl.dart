import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
//import 'package:aplicacion_mundo_otaku/feautures/products/infrastructure/datasources/products_datasource_impl.dart';

class ProductsRepositoryImpl extends ProductsRepository{

  final ProductDatasource datasource;

  ProductsRepositoryImpl( this.datasource );
  

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) {
    return datasource.createUpdateProduct(productLike);
  }

  @override
  Future<Product> getProductById(String id) {
    return datasource.getProductById(id);
  }

  @override
  Future<List<Product>> getProductsByPage({int limit = 10, int offset = 0}) {
    return datasource.getProductByPage(limit: limit, offset: offset);
  }

  @override
  Future<List<Product>> searchProductByTerm(String term) {
    return datasource.searchProductByTerm(term);
  }

}