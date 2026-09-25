import 'package:aplicacion_mundo_otaku/config/constants/environment.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = Dio(BaseOptions(baseUrl: Environment.apiUrl));
  const secureStorage = FlutterSecureStorage();
  dio.interceptors.add(TokenInterceptor(secureStorage));

  return AuthNotifier(
    authRepository: AuthRepositoryImpl(dio: dio, secureStorage: secureStorage),
    authDataSource: AuthDataSourceImpl(dio: dio, secureStorage: secureStorage),
    secureStorage: secureStorage,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final AuthDataSource authDataSource;
  final FlutterSecureStorage secureStorage;

  AuthNotifier({
    required this.authRepository,
    required this.authDataSource,
    required this.secureStorage,
  }) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> loginUser(String email, String password) async {
    try {
      final user = await authRepository.login(email, password);
      await _setLoggedUser(user);
    } on CustomError catch (error) {
      await _clearLocalSession(error.message);
    } catch (_) {
      await _clearLocalSession('No fue posible iniciar sesión.');
    }
  }

  Future<void> registerUser(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final user = await authRepository.register(email, password, fullName);
      await _setLoggedUser(
        user,
        message: '¡Registro exitoso! ¡Bienvenido a la comunidad!',
      );
    } on CustomError catch (error) {
      await _clearLocalSession(error.message);
    } catch (_) {
      await _clearLocalSession('No fue posible crear la cuenta.');
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await secureStorage.read(key: 'auth_token');
    if (token == null) {
      _setUnauthenticated();
      return;
    }

    try {
      final user = await authRepository.checkAuthStatus(token);
      await _setLoggedUser(user);
    } catch (_) {
      await _clearLocalSession();
    }
  }

  Future<String?> getToken() {
    return secureStorage.read(key: 'auth_token');
  }

  Future<void> _setLoggedUser(
    User user, {
    String message = '¡Revisa lo que la comunidad tiene para ofrecer! :)',
  }) async {
    await secureStorage.write(key: 'auth_token', value: user.token);
    SocketService.instance.initialize(token: user.token);
    state = state.copyWith(
      user: user,
      authStatus: AuthStatus.authenticated,
      errorMessage: message,
    );
  }

  Future<void> logout([String? errorMessage]) async {
    try {
      await authDataSource.logout();
    } catch (_) {
      // El cierre local debe completarse aunque la API no esté disponible.
    } finally {
      await _clearLocalSession(errorMessage);
    }
  }

  Future<void> expireSession() async {
    await _clearLocalSession(
      'Tu sesión expiró. Inicia sesión nuevamente.',
    );
  }

  Future<void> _clearLocalSession([String? errorMessage]) async {
    SocketService.instance.disconnect();
    await secureStorage.delete(key: 'auth_token');
    _setUnauthenticated(errorMessage);
  }

  void _setUnauthenticated([String? errorMessage]) {
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      clearUser: true,
      errorMessage: errorMessage,
    );
  }
}

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking,
    this.user,
    this.errorMessage = '',
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    bool clearUser = false,
    String? errorMessage,
  }) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
      user: clearUser ? null : user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
