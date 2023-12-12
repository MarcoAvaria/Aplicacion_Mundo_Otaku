import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

//! 3 - StateNotifierProvider - Consume Afuera

final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
  
  final registerUserCallback = ref.watch(authProvider.notifier).registerUser;
  
  return  RegisterFormNotifier(
    registerUserCallback: registerUserCallback,
  );
});

//! 2 - Como implementamos un notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {

  final Function(String, String, String) registerUserCallback;

  RegisterFormNotifier({
    required this.registerUserCallback,
  }): super( RegisterFormState() );

  onEmailChange( String value ) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([ newEmail, state.password ])
    );
  }

  onFullNameChange( String value ) {
    final newfullName = Fullname.dirty(value);
    state = state.copyWith(
      fullName: newfullName,
      isValid: Formz.validate([ newfullName, state.fullName ])
    );
  }

  onPasswordChanged( String value ) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([ newPassword, state.email ])
    );
  }

  onFormSubmit() async {
    _touchEveryField();
    print({state.isValid});
    if( !state.isValid ) return;
    await registerUserCallback( state.email.value, state.password.value, state.fullName.value );

    state = state.copyWith( isPosting: false);
  }

  _touchEveryField() {
    print('Entra en _touchEveryField!');
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);
    final fullName = Fullname.dirty(state.fullName.value);
    //final fullName = state.

    state = state.copyWith(
      isFormPosted: true,
      email: email,
      password: password,
      fullName: fullName,
      isValid: Formz.validate([ email, password, fullName ])
    );
  }
}

//! 1 - State del provider
class RegisterFormState {

  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Email email;
  final Password password;
  final Fullname fullName;

  RegisterFormState({
    this.isPosting = false, 
    this.isFormPosted = false, 
    this.isValid = false, 
    this.email = const Email.pure(), 
    this.password = const Password.pure(),
    this.fullName = const Fullname.pure()
  });

  RegisterFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    Email? email,
    Password? password,
    Fullname? fullName,

  }) => RegisterFormState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    email: email ?? this.email,
    password: password ?? this.password,
    fullName: fullName ?? this.fullName
  );

  @override
  String toString(){
    return '''
  LoginFormState:
    isPosting = $isPosting 
    isFormPosted = $isFormPosted 
    isValid = $isValid 
    email = $email 
    password = $password
    fullName = $fullName
''';
  }

}
