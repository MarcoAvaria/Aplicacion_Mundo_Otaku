import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

class LoginScreen extends StatelessWidget {
  static const String name = 'login_screen';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      const Icon(Icons.lock, size: 40),
                      Container(
                        height: size.height -
                            130, // 80 los dos sizebox y 100 el ícono
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(100)),
                        ),
                        child: const _LoginForm(),
                      )
                    ]))));
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode()..addListener(_synchronizeEmail);
    _passwordFocusNode = FocusNode()..addListener(_synchronizePassword);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.authStatus == AuthStatus.notAuthenticated &&
          authState.errorMessage.isNotEmpty) {
        showSnackbar(context, authState.errorMessage);
      }
    });
  }

  void _synchronizeEmail() {
    if (!_emailFocusNode.hasFocus) {
      ref.read(loginFormProvider.notifier).onEmailChange(_emailController.text);
    }
  }

  void _synchronizePassword() {
    if (!_passwordFocusNode.hasFocus) {
      ref
          .read(loginFormProvider.notifier)
          .onPasswordChanged(_passwordController.text);
    }
  }

  @override
  void dispose() {
    _emailFocusNode
      ..removeListener(_synchronizeEmail)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_synchronizePassword)
      ..dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loginForm = ref.watch(loginFormProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isEmpty) return;
      showSnackbar(context, next.errorMessage);
      if (next.authStatus == AuthStatus.authenticated) {
        context.push(AppRoutes.discover);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '¡Bienvenid@! Te hemos extrañado :(',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          MyFieldText(
              varTextCtrl: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
              errorMessage:
                  loginForm.isFormPosted ? loginForm.email.errorMessage : null,
              label: "El correo de tu cuenta",
              darkText: false),
          const SizedBox(height: 15),
          MyFieldText(
            varTextCtrl: _passwordController,
            focusNode: _passwordFocusNode,
            label: "Contraseña",
            darkText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: (_) =>
                ref.read(loginFormProvider.notifier).onFormSubmit(),
            errorMessage:
                loginForm.isFormPosted ? loginForm.password.errorMessage : null,
          ),
          const SizedBox(height: 15),
          //const NewWidgetRecuperarPass(),

          const SizedBox(height: 30),

          SizedBox(
              width: double.infinity,
              height: 60,
              child: ButtonLogin(
                text: 'Iniciar sesión',
                onPressed: loginForm.isPosting
                    ? null
                    //: ref.read(loginFormProvider.notifier).onFormSubmit
                    : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref.read(loginFormProvider.notifier).onFormSubmit();
                      },
              )),
          const SizedBox(height: 30),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('Crea una aquí'))
            ],
          ),
        ],
      ),
    );
  }
}
