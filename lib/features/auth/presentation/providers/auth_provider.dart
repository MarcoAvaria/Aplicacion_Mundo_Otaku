import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/key_value_storage_service.dart';
import 'package:aplicacion_mundo_otaku/features/shared/infrastructure/services/key_value_storage_service_impl.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = AuthRepositoryImpl();
  final keyValueStorageService = KeyValueStorageServiceImpl();

  return AuthNotifier(
      authRepository: authRepository,
      keyValueStorageService: keyValueStorageService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService,
  }) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> loginUser(String email, String password) async {
    //await Future.delayed(const Duration(milliseconds: 500));
    try {
      final user = await authRepository.login(email, password);
      _setLoggedUser(user);
    } on CustomError catch (e) {
      logout(e.message);
    } catch (e) {
      logout('¡Error no controlado!');
    }
    //final user = await authRepository.login( email, password );
    //state = state.copyWith( authStatus, user, errorMessage );
  }

  Future<void> registerUser(
      String email, String password, String fullName) async {
    print('Entro a registerUser!');
    try {
      final user = await authRepository.register(email, password, fullName);
      _setRegisterUser(user); // Llama al nuevo método
    } on CustomError catch (e) {
      logout(e.message);
    } catch (e) {
      print('Capturado un error no esperado: $e');
      //print('Capturado un error no esperado: ${e.runtimeType}: ${e.toString()}');
      //print('Capturado un error no esperado: ${e.runtimeType}: ${(e as WrongCredentials).getMessage()}');
      print('Capturado un error no esperado: ${e.runtimeType}: $e');
      logout('¡Error no controlado!');
    }
  }

  void checkAuthStatus() async {
    final token = await keyValueStorageService.getValue<String>('token');
    if (token == null) return logout();

    try {
      final user = await authRepository.checkAuthStatus(token);
      _setLoggedUser(user);
    } catch (e) {
      //print('Fallo checkAuthStatus :( !!! )');
      logout();
    }
  }

  void _setRegisterUser(User user) {
    // Puedes realizar acciones adicionales aquí si es necesario
    state = state.copyWith(
        user: user,
        authStatus: AuthStatus.authenticated,
        errorMessage: '¡Registro exitoso! ¡Bienvenido a la comunidad!');
  }

  void _setLoggedUser(User user) async {
    //print('Dentro de _setLoggedUser');

    await keyValueStorageService.setKeyValue('token', user.token);

    state = state.copyWith(
        user: user,
        authStatus: AuthStatus.authenticated,
        errorMessage: '¡Revisa lo que la comunidad tiene para ofrecer! :)');
  }

  Future<void> logout([String? errorMessage]) async {
    await keyValueStorageService.removeKey('token');

    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
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
    String? errorMessage,
  }) =>
      AuthState(
        authStatus: authStatus ?? this.authStatus,
        user: user ?? this.user,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
