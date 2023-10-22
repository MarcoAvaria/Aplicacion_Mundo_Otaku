// import 'package:aplicacion_mundo_otaku/feautures/shared/shared.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:formz/formz.dart';

// //! 3 - StateNotifierProvider - Consume Afuera

// final registerFormProvider = StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((ref) {
//   return  RegisterFormNotifier();
// });

// //! 2 - Como implementamos un notifier
// class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
//   RegisterFormNotifier(): super( RegisterFormState() );

//   onEmailChange( String value ) {
//     final newEmail = Email.dirty(value);
//     state = state.copyWith(
//       email: newEmail,
//       isValid: Formz.validate([ newEmail, state.password ])
//     );
//   }

//   onPasswordChanged( String value ) {
//     final newPassword = Password.dirty(value);
//     state = state.copyWith(
//       password: newPassword,
//       isValid: Formz.validate([ newPassword, state.email ])
//     );
//   }

//   onFormSubmit() {
//     _touchEveryField();

//     if( !state.isValid ) return;
//   }

//   _touchEveryField() {

//     final email = Email.dirty(state.email.value);
//     final password = Password.dirty(state.password.value);

//     state = state.copyWith(
//       isFormPosted: true,
//       email: email,
//       password: password,
//       isValid: Formz.validate([ email, password ])
//     );
//   }
// }

// //! 1 - State del provider
// class RegisterFormState {

//   final bool isPosting;
//   final bool isFormPosted;
//   final bool isValid;
//   final Email email;
//   final Password password;

//   RegisterFormState({
//     this.isPosting = false, 
//     this.isFormPosted = false, 
//     this.isValid = false, 
//     this.email = const Email.pure(), 
//     this.password = const Password.pure()
//   });

//   RegisterFormState copyWith({
//     bool? isPosting,
//     bool? isFormPosted,
//     bool? isValid,
//     Email? email,
//     Password? password,
//   }) => RegisterFormState(
//     isPosting: isPosting ?? this.isPosting,
//     isFormPosted: isFormPosted ?? this.isFormPosted,
//     isValid: isValid ?? this.isValid,
//     email: email ?? this.email,
//     password: password ?? this.password,
//   );

//   @override
//   String toString(){
//     return '''
//   LoginFormState:
//     isPosting = $isPosting 
//     isFormPosted = $isFormPosted 
//     isValid = $isValid 
//     email = $email 
//     password = $password
// ''';
//   }

// }
