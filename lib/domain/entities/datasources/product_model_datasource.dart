import '../product_model_post.dart';

abstract class ProductModelDatasource {

  Future<List<ProductModel>> getFeedProductByPage( int page );
}