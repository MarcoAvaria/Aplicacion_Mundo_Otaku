import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/infrastructure/infraestructure.dart';

import 'package:dio/dio.dart';

class AuthDataSourceImpl extends AuthDataSource {
  final dio = Dio(BaseOptions(
    baseUrl: Enviroment.apiUrl,
  ));

  @override
  Future<User> checkAuthStatus(String token) async {
    try {
      final response = await dio.get('/auth/check-status',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      final user = UserMapper.userJsonToEntity(response.data);
      return user;


    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw CustomError('Token no es correcto');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        throw CustomError('Revisa la conexión de internet :O');
      }
      throw Exception();
      //throw CustomError('Something wrong happend :O !', 3460);
    } catch (e) {
      throw CustomError('Something wrong happend :O 222!');
      //throw CustomError('Something wrong happend :O !', 4460);
    }
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await dio
          .post('/auth/login', data: {'email': email, 'password': password});

      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw CustomError(
            e.response?.data['message'] ?? 'Credenciales Incorrectas :O ');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        throw CustomError('Revisa la conexión de internet :O');
      }
      throw Exception();
      //throw CustomError('Something wrong happend :O !', 3460);
    } catch (e) {
      throw CustomError('Something wrong happend :O 222!');
      //throw CustomError('Something wrong happend :O !', 4460);
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    throw WrongCredentials();
  }
}
