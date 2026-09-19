import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef UnauthorizedCallback = Future<void> Function();

class TokenInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;

  TokenInterceptor(this.secureStorage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await secureStorage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

class UnauthorizedInterceptor extends Interceptor {
  final UnauthorizedCallback onUnauthorized;
  bool _isHandlingUnauthorized = false;

  UnauthorizedInterceptor(this.onUnauthorized);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_isHandlingUnauthorized) {
      _isHandlingUnauthorized = true;
      onUnauthorized().whenComplete(() => _isHandlingUnauthorized = false);
    }
    handler.next(err);
  }
}
