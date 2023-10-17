import 'package:aplicacion_mundo_otaku/feautures/auth/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/infrastructure/infraestructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier,AuthState>( (ref) {

  final authRepository = AuthRepositoryImpl();

  return AuthNotifier(
    authRepository: authRepository,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {

  final AuthRepository authRepository;

  AuthNotifier({
    required this.authRepository
  }): super( AuthState() );

  void loginUser(String email, String password) async {

    final user = await authRepository.login( email, password );
    //state = state.copyWith( authStatus, user, errorMessage );

  }

  void registerUser(String email, String password) async {
    
  }

  void checkAuthStatus() async {
    
  }
  
}

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  
  final AuthStatus authStatus;
  final User? user;
  final String errorMessage;

  AuthState({
    this.authStatus = AuthStatus.checking, 
    this.user , 
    this.errorMessage = '',
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    String? errorMessage,
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}