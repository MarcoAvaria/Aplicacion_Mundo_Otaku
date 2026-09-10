import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  static const String name = 'register_screen';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      eyebrow: 'Únete a la comunidad',
      title: 'Dale otra vida a tu colección.',
      description:
          'Crea tu perfil para publicar piezas, proponer intercambios y conversar de forma segura.',
      child: _RegisterForm(),
    );
  }
}

class _RegisterForm extends ConsumerWidget {
  const _RegisterForm();

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerForm = ref.watch(registerFormProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty ||
          next.errorMessage == previous?.errorMessage) {
        return;
      }
      _showSnackbar(context, next.errorMessage);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyFieldText(
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          prefixIcon: Icons.person_outline_rounded,
          onChanged: ref.read(registerFormProvider.notifier).onFullNameChange,
          errorMessage: registerForm.isFormPosted
              ? registerForm.fullName.errorMessage
              : null,
          label: 'Nombre público',
        ),
        const SizedBox(height: 14),
        MyFieldText(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          prefixIcon: Icons.alternate_email_rounded,
          onChanged: ref.read(registerFormProvider.notifier).onEmailChange,
          errorMessage: registerForm.isFormPosted
              ? registerForm.email.errorMessage
              : null,
          label: 'Correo electrónico',
        ),
        const SizedBox(height: 14),
        MyFieldText(
          label: 'Contraseña',
          darkText: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          prefixIcon: Icons.lock_outline_rounded,
          onChanged: ref.read(registerFormProvider.notifier).onPasswordChanged,
          errorMessage: registerForm.isFormPosted
              ? registerForm.password.errorMessage
              : null,
        ),
        const SizedBox(height: 14),
        MyFieldText(
          label: 'Confirmar contraseña',
          darkText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          prefixIcon: Icons.verified_user_outlined,
          onChanged:
              ref.read(registerFormProvider.notifier).onConfirmPasswordChanged,
          onFieldSubmitted: (_) =>
              ref.read(registerFormProvider.notifier).onFormSubmit(),
          errorMessage: registerForm.isFormPosted &&
                  registerForm.confirmPassword != registerForm.password.value
              ? 'Las contraseñas no coinciden'
              : null,
        ),
        const SizedBox(height: 22),
        ButtonLogin(
          text: registerForm.isPosting ? 'Creando cuenta…' : 'Crear mi cuenta',
          onPressed: registerForm.isPosting
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  ref.read(registerFormProvider.notifier).onFormSubmit();
                },
        ),
        const SizedBox(height: 18),
        Text(
          'Al crear tu cuenta aceptas participar con respeto y cuidar cada intercambio.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿Ya eres parte?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ],
    );
  }
}
