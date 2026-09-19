import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/register_form_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterFormNotifier', () {
    test('does not submit when password confirmation differs', () async {
      var submissions = 0;
      final notifier = RegisterFormNotifier(
        registerUserCallback: (_, __, ___) async => submissions++,
      );

      notifier.onFullNameChange('Usuario Demo');
      notifier.onEmailChange('usuario@mundo-otaku.demo');
      notifier.onPasswordChanged('secure-password');
      notifier.onConfirmPasswordChanged('different-password');
      await notifier.onFormSubmit();

      expect(notifier.state.isValid, isFalse);
      expect(notifier.state.isFormPosted, isTrue);
      expect(submissions, 0);
    });

    test('submits validated and matching credentials once', () async {
      final submissions = <List<String>>[];
      final notifier = RegisterFormNotifier(
        registerUserCallback: (email, password, fullName) async {
          submissions.add([email, password, fullName]);
        },
      );

      notifier.onFullNameChange('Usuario Demo');
      notifier.onEmailChange('usuario@mundo-otaku.demo');
      notifier.onPasswordChanged('secure-password');
      notifier.onConfirmPasswordChanged('secure-password');
      await notifier.onFormSubmit();

      expect(notifier.state.isValid, isTrue);
      expect(notifier.state.isPosting, isFalse);
      expect(submissions, [
        ['usuario@mundo-otaku.demo', 'secure-password', 'Usuario Demo'],
      ]);
    });
  });
}
