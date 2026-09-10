import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  static const String name = 'login_screen';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      eyebrow: 'Bienvenido de vuelta',
      title: 'Tu próxima pieza está esperando.',
      description:
          'Entra a tu cuenta para revisar intercambios, mensajes y nuevos hallazgos de la comunidad.',
      child: _LoginForm(),
    );
  }
}

/// Compatibilidad con la pantalla histórica conservada en el repositorio.
class GoogleOutlookSignIn extends StatelessWidget {
  const GoogleOutlookSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SquareTile(imagePath: 'assets/google_image.png'),
        SizedBox(width: 25),
        SquareTile(imagePath: 'assets/outlook_image.png'),
      ],
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  String? _activeDemo;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loginDemo(String account) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _activeDemo = account);

    await ref.read(authProvider.notifier).loginUser(
          '$account@mundo-otaku.demo',
          account == 'usuario1' ? 'MundoOtakuDemo1!' : 'MundoOtakuDemo2!',
        );

    if (mounted) setState(() => _activeDemo = null);
  }

  @override
  Widget build(BuildContext context) {
    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty ||
          next.errorMessage == previous?.errorMessage) {
        return;
      }
      _showSnackbar(next.errorMessage);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyFieldText(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          prefixIcon: Icons.alternate_email_rounded,
          onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
          errorMessage:
              loginForm.isFormPosted ? loginForm.email.errorMessage : null,
          label: 'Correo electrónico',
        ),
        const SizedBox(height: 16),
        MyFieldText(
          label: 'Contraseña',
          darkText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          prefixIcon: Icons.lock_outline_rounded,
          onChanged: ref.read(loginFormProvider.notifier).onPasswordChanged,
          onFieldSubmitted: (_) =>
              ref.read(loginFormProvider.notifier).onFormSubmit(),
          errorMessage:
              loginForm.isFormPosted ? loginForm.password.errorMessage : null,
        ),
        const SizedBox(height: 22),
        ButtonLogin(
          text: loginForm.isPosting ? 'Entrando…' : 'Iniciar sesión',
          onPressed: loginForm.isPosting || _activeDemo != null
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  ref.read(loginFormProvider.notifier).onFormSubmit();
                },
        ),
        const SizedBox(height: 28),
        const _DividerLabel(label: 'O EXPLORA LA DEMO'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _DemoAccountButton(
                number: '01',
                label: 'Colección manga',
                isLoading: _activeDemo == 'usuario1',
                onPressed:
                    _activeDemo == null ? () => _loginDemo('usuario1') : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DemoAccountButton(
                number: '02',
                label: 'Figuras y tomos',
                isLoading: _activeDemo == 'usuario2',
                onPressed:
                    _activeDemo == null ? () => _loginDemo('usuario2') : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿Aún no tienes cuenta?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Crear una cuenta'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: MundoOtakuColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _DemoAccountButton extends StatelessWidget {
  final String number;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _DemoAccountButton({
    required this.number,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: MundoOtakuColors.outline),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MundoOtakuColors.night,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          color: MundoOtakuColors.mint,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        number,
                        style: const TextStyle(
                          color: MundoOtakuColors.mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: MundoOtakuColors.ink,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
