//import 'package:aplicacion_mundo_otaku/feautures/auth/domain/entities/user.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';

class UserMapper {

  static User userJsonToEntity( Map<String,dynamic> json ) => User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      roles: List<String>.from(json['roles'].map( ( role ) => role)),
      token: json['token'] ?? ''
    );
}