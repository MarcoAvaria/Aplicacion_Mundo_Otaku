import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage secureStorage;

  AuthService({required this.secureStorage});

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'auth_token');
    notifyListeners();
  }
}