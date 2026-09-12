import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthDataSourceImpl extends AuthDataSource with ChangeNotifier {
  // final dio = Dio(BaseOptions(
  //   baseUrl: Environment.apiUrl,
  // ));
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  AuthDataSourceImpl({required this.dio, required this.secureStorage});

  @override
  Future<User> checkAuthStatus(String token) async {
    try {
      final response = await dio.get(ApiEndpoints.authStatus,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return UserMapper.userJsonToEntity(response.data);
      // return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw CustomError('Token no es correcto :o');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        throw CustomError('Revisa la conexión de internet :O');
      }
      throw Exception();
    } catch (e) {
      throw CustomError('Something wrong happend :O 222!');
    }
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await dio.post(ApiEndpoints.authLogin,
          data: {'email': email, 'password': password});
      final user = UserMapper.userJsonToEntity(response.data);

      return user;
    } on DioException catch (e) {
      String errorMessage = 'Credenciales incorrectas.';
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['message'] is String) {
          errorMessage = data['message'];
        }
        throw CustomError(errorMessage);
      }
      if (_isNetworkFailure(e)) {
        throw CustomError(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        );
      }
      throw CustomError('No fue posible iniciar sesión. Inténtalo nuevamente.');
    } on CustomError {
      rethrow;
    } catch (_) {
      throw CustomError('No fue posible iniciar sesión. Inténtalo nuevamente.');
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) async {
    try {
      final response = await dio.post(ApiEndpoints.authRegister,
          data: {'email': email, 'password': password, 'fullName': fullName});
      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw CustomError(
            e.response?.data['message'] ?? 'Credenciales Incorrectas :O ');
      }
      if (_isNetworkFailure(e)) {
        throw CustomError(
          'No fue posible conectar con el servidor. Revisa tu conexión.',
        );
      }
      throw CustomError(
          'No fue posible crear la cuenta. Inténtalo nuevamente.');
    } on CustomError {
      rethrow;
    } catch (_) {
      throw CustomError(
          'No fue posible crear la cuenta. Inténtalo nuevamente.');
    }
  }

  @override
  Future<String> getUserId(String token) async {
    try {
      final response = await dio.get(ApiEndpoints.authStatus,
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      final user = UserMapper.userJsonToEntity(response.data);
      return user.id;
    } catch (e) {
      throw CustomError('No se pudo obtener el ID del usuario');
    }
  }

  // @override
  // Future<void> logout() {
  //   // TODO: implement logout
  //   throw UnimplementedError();
  // }

  @override
  Future<void> logout() async {
    final token = await secureStorage.read(key: 'auth_token');
    if (token == null) return;

    await dio.post(ApiEndpoints.authLogout,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  bool _isNetworkFailure(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };
  }
}
