import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/infrastructure/infraestructure.dart';

import 'package:dio/dio.dart';

class AuthDataSourceImpl extends AuthDataSource {

  final dio = Dio(
    BaseOptions(
      baseUrl: Enviroment.apiUrl,      
    )
  );
  
  @override
  Future<User> checkAuthStatus(String token) {
    // TODO: implement checkAuthStatus
    throw UnimplementedError();
  }

  @override
  Future<User> login(String email, String password) async {
    
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });

      final user = UserMapper.userJsonToEntity( response.data );
      return user;

    } catch ( e ){
      throw UnimplementedError();
    }
  }

  @override
  Future<User> register(String email, String password, String fullName) {
    throw WrongCredentials();
  }


} 