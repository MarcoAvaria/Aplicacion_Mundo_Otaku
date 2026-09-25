import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:formz/formz.dart';

//! 3 - StateNotifierProvider - Consume Afuera

final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  final loginUserCallback = ref.watch(authProvider.notifier).loginUser;

  return LoginFormNotifier(
    loginUserCallback: loginUserCallback,
  );
});

//! 2 - Como implementamos un notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final Function(String, String) loginUserCallback;

  LoginFormNotifier({
    required this.loginUserCallback,
  }) : super(LoginFormState());

  onEmailChange(String value) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
        email: newEmail, isValid: Formz.validate([newEmail, state.password]));
  }

  onPasswordChanged(String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
        password: newPassword,
        isValid: Formz.validate([newPassword, state.email]));
  }

  onFormSubmit() async {
    _touchEveryField();
    // print({state.isValid});
    if (!state.isValid) return;

    try {
      // Normalizado (sin espacios y en minúsculas), que es como lo guarda la
      // API: así un correo pegado con un espacio al final también entra.
      await loginUserCallback(state.email.normalizado, state.password.value);
      state = state.copyWith(isPosting: false);
    } catch (e) {
      state = state.copyWith(isPosting: false, errorMessage: e.toString());
    }

    // print("------------------EXITOSO PASO POR ACÁ 0001 ------------------");
    // await loginUserCallback( state.email.value, state.password.value );
    // print("------------------EXITOSO PASO POR ACÁ 00022 ------------------");
    // state = state.copyWith( isPosting: false);

    //print(state);
  }

  _touchEveryField() {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);

    state = state.copyWith(
        isFormPosted: true,
        email: email,
        password: password,
        isValid: Formz.validate([email, password]));
  }
}

//! 1 - State del provider
class LoginFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Email email;
  final Password password;
  final String errorMessage;

  LoginFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.errorMessage = '',
  });

  LoginFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    Email? email,
    Password? password,
    String? errorMessage,
  }) =>
      LoginFormState(
        isPosting: isPosting ?? this.isPosting,
        isFormPosted: isFormPosted ?? this.isFormPosted,
        isValid: isValid ?? this.isValid,
        email: email ?? this.email,
        password: password ?? this.password,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  String toString() {
    return '''
  LoginFormState:
    isPosting = $isPosting 
    isFormPosted = $isFormPosted 
    isValid = $isValid 
    email = $email 
    password = $password
    errorMessage = $errorMessage
''';
  }
}
