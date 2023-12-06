//import 'package:aplicacion_mundo_otaku/features/products/infrastructure/errors/product_errors.dart';
import 'package:dio/dio.dart';
import 'package:aplicacion_mundo_otaku/features/products/infrastructure/infrastructure.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:http_parser/http_parser.dart';

class ProductsDatasourceImpl extends ProductDatasource {
  
  late final Dio dio;
  final String accessToken;

  ProductsDatasourceImpl({
    required this.accessToken
  }) : dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      headers: {
        'Authorization': 'Bearer $accessToken'
      }
    )
  );

  Future<String> _uploadFile( String path ) async {
    
    try {
      final fileName = path.split('/').last;
      final contentType = path.split('.').last;
      /*
      final FormData data = FormData.fromMap( {
        'file': MultipartFile.fromFileSync( path, filename: fileName)
      });
      */
      final FormData data = FormData.fromMap( {
        'file': MultipartFile.fromFileSync(
          path, 
          filename: fileName,
          contentType: MediaType('image', contentType),
        ),
      });
      final response = await dio.post('/files/product', data: data );

      return response.data['image'];

    } catch (e) {
      throw Exception(); 
    }

  }


  Future<List<String>> _uploadPhotos( List<String> photos ) async {

    final photosToUpload = photos.where((element) => element.contains('/') ).toList();
    final photosToIgnore = photos.where((element) => !element.contains('/') ).toList();

    final List<Future<String>> uploadJob = photosToUpload.map(_uploadFile).toList();
    final newImages = await Future.wait(uploadJob); 

    return [...photosToIgnore, ...newImages ];
  }

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) async {
    
    try {

      final String? productId = productLike['id'];
      //print(productId);
      final String method = (productId == null) ? 'POST':'PATCH';
      //print(method);
      final String url = (productId == null ) ? '/products':'/products/$productId';
      //print(url);


      productLike.remove('id');
      productLike['images'] = await _uploadPhotos( productLike['images'] );

      //throw Exception();

      final response = await dio.request(
        url,
        data: productLike,
        options: Options(
          method: method
        )
      );
      final product = ProductMapper.jsonToEntity(response.data);
      //print(product);
      return product;

    } catch (e) {
      //print(e);
      throw Exception();
    }


    //throw UnimplementedError();
  }

  @override
  Future<Product> getProductById(String id) async {
    
    try{
      final response = await dio.get('/products/$id');
      final product = ProductMapper.jsonToEntity(response.data);
      return product;

    } on DioException catch ( e ) {
      if ( e.response!.statusCode == 404 ) throw ProductNotFound();
      throw Exception();
    } catch ( e ) {
      throw Exception();
    }
  }

  @override
  Future<List<Product>> getProductByPage({int limit = 10, int offset = 0}) async {
    final response = await dio.get<List>('/products?limit=$limit&offset=$offset');
    final List<Product> products = [];
    for (final product in response.data ?? [] ) {
      products.add( ProductMapper.jsonToEntity(product) ); // mapper
    }
    return products;
  }

  @override
  Future<List<Product>> searchProductByTerm(String term) {
    // TODO: implement searchProductByTerm
    throw UnimplementedError();
  }

}