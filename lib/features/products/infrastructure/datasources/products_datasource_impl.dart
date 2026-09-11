import 'package:dio/dio.dart';
import 'package:aplicacion_mundo_otaku/features/products/infrastructure/infrastructure.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/image_file_type.dart';

class ProductsDatasourceImpl extends ProductDatasource {
  late final Dio dio;
  final String accessToken;

  ProductsDatasourceImpl({required this.accessToken})
      : dio = Dio(BaseOptions(
            baseUrl: Environment.apiUrl,
            headers: {'Authorization': 'Bearer $accessToken'}));

  Future<String> _uploadFile(String path) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final fileType = detectImageFileType(bytes);
      final fileName = 'product.${fileType.extension}';
      final FormData data = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType('image', fileType.mimeSubtype),
        ),
      });
      final response = await dio.post('/files/product', data: data);

      return response.data['image'];
    } on FormatException {
      rethrow;
    } catch (_) {
      throw Exception('No fue posible subir la imagen.');
    }
  }

  Future<List<String>> _uploadPhotos(List<String> photos) async {
    final photosToUpload = photos.where(isPendingImageUploadPath).toList();
    final photosToKeep = photos
        .where((photo) => !isPendingImageUploadPath(photo))
        .map(imageReferenceForApi)
        .toList();

    final List<Future<String>> uploadJob =
        photosToUpload.map(_uploadFile).toList();
    final newImages = await Future.wait(uploadJob);

    return [...photosToKeep, ...newImages];
  }

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) async {
    try {
      final String? productId = productLike['id'];
      //print(productId);
      final String method = (productId == null) ? 'POST' : 'PATCH';
      //print(method);
      final String url =
          (productId == null) ? '/products' : '/products/$productId';
      //print(url);

      productLike.remove('id');
      productLike['images'] = await _uploadPhotos(productLike['images']);

      //throw Exception();

      final response = await dio.request(url,
          data: productLike, options: Options(method: method));
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
    try {
      final response = await dio.get('/products/$id');
      final product = ProductMapper.jsonToEntity(response.data);
      return product;
    } on DioException catch (e) {
      if (e.response!.statusCode == 404) throw ProductNotFound();
      throw Exception();
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<List<Product>> getProductByPage(
      {int limit = 10, int offset = 0}) async {
    final response = await dio.get<List>(
      '/products',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final List<Product> products = [];
    for (final product in response.data ?? []) {
      products.add(ProductMapper.jsonToEntity(product)); // mapper
    }
    return products;
  }

  @override
  Future<List<Product>> getProductsForCurrentUser(String userId) async {
    try {
      final response = await dio.get<List<dynamic>>('/products/mine');

      return List<Product>.from(
        (response.data ?? []).map((dynamic productJson) {
          return ProductMapper.jsonToEntity(
              productJson as Map<String, dynamic>);
        }),
      );
    } catch (e) {
      throw Exception();
    }
  }

  @override
  Future<List<Product>> searchProductByTerm(String term) async {
    final normalizedTerm = term.trim();
    if (normalizedTerm.length < 2) return [];

    final response = await dio.get<List>(
      '/products',
      queryParameters: {'term': normalizedTerm, 'limit': 50},
    );

    return List<Product>.from(
      (response.data ?? []).map((dynamic productJson) {
        return ProductMapper.jsonToEntity(
          productJson as Map<String, dynamic>,
        );
      }),
    );
  }
}
