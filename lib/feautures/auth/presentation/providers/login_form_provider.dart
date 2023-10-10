
//! 1 - State del provider
import 'package:aplicacion_mundo_otaku/feautures/shared/shared.dart';

class LoginFormState {

  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Email email;
  final Password password;

  LoginFormState({
    this.isPosting = false, 
    this.isFormPosted = false, 
    this.isValid = false, 
    this.email = const Email.pure(), 
    this.password = const Password.pure()
  });

}

//! 2 - Como implementamos un notifier

//! 3 - StateNotifierProvider - Consume Afuera