import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';

import 'package:dio/dio.dart';

class AuthDataSourceImpl extends AuthDataSource {
  
  final dio = Dio(BaseOptions(
    baseUrl: Environment.apiUrl,
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
     } catch (e) {
      throw CustomError('Something wrong happend :O 222!');
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
        //print('Algo paso :/ 3');
        throw CustomError(
            e.response?.data['message'] ?? 'Credenciales Incorrectas :O ');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        //print('Algo paso :/ 2');
        throw CustomError('Revisa la conexión de internet :O');
      }
      //print('Algo paso :/ 1');
      throw Exception();

      //throw CustomError('Something wrong happend :O !', 3460);
    } catch (e) {
      //print('Algo paso :/ 5');
      throw CustomError('Something wrong happend :O 222!');
      //throw CustomError('Something wrong happend :O !', 4460);
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) async {
    try {
      final response = await dio
          .post('/auth/register', data: {'email': email, 'password': password, 'fullName': fullName});

      final user = UserMapper.userJsonToEntity(response.data);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        print('Algo paso :/ 3');
        throw CustomError(
            e.response?.data['message'] ?? 'Credenciales Incorrectas :O ');
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        print('Algo paso :/ 2');
        throw CustomError('Revisa la conexión de internet :O');
      }
      print('Algo paso :/ 1');
      //throw Exception();

      throw CustomError('Something wrong happend :O !3460', );
    } catch (e) {
      print('Algo paso :/ 5');
      throw CustomError('Something wrong happend :O 222!');
      //throw CustomError('Something wrong happend :O !', 4460);
    }
    throw WrongCredentials();
  }

  @override
  Future<String> getUserId(String token) async {
    try {
      final response = await dio.get('/auth/check-auth-status',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      final user = UserMapper.userJsonToEntity(response.data);
      return user.id;
    } catch (e) {
      // Maneja los errores según tus necesidades
      throw CustomError('No se pudo obtener el ID del usuario');
    }
  }
}
