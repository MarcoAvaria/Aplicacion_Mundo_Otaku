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
                        child: const _RegisterForm(),
                      )
                    ]))));
  }
}

class _RegisterForm extends ConsumerWidget {
  const _RegisterForm();

  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerForm = ref.watch(registerFormProvider);

    ref.listen(authProvider, ((previous, next) {
      if (next.errorMessage.isEmpty) return;
      showSnackbar(context, next.errorMessage);
    }));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '¿Qué esperas? ¡Crea tu cuenta ahora!',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          MyFieldText(
              keyboardType: TextInputType.name,
              onChanged:
                  ref.read(registerFormProvider.notifier).onFullNameChange,
              errorMessage: registerForm.isFormPosted
                  ? registerForm.fullName.errorMessage
                  : null,
              label: "Tu nombre acá",
              darkText: false),
          const SizedBox(height: 15),
          MyFieldText(
              keyboardType: TextInputType.emailAddress,
              onChanged: ref.read(registerFormProvider.notifier).onEmailChange,
              errorMessage: registerForm.isFormPosted
                  ? registerForm.email.errorMessage
                  : null,
              label: "Tu correo para tu nueva cuenta",
              darkText: false),
          const SizedBox(height: 15),
          MyFieldText(
            label: "Ingrese la contraseña",
            darkText: true,
            onChanged:
                ref.read(registerFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: (_) =>
                ref.read(registerFormProvider.notifier).onFormSubmit(),
            errorMessage: registerForm.isFormPosted
                ? registerForm.password.errorMessage
                : null,
          ),
          const SizedBox(height: 15),
          MyFieldText(
            label: "Vuelva a ingresar la contraseña",
            darkText: true,
            onChanged:
                ref.read(registerFormProvider.notifier).onPasswordChanged,
            onFieldSubmitted: (_) =>
                ref.read(registerFormProvider.notifier).onFormSubmit(),
            errorMessage: registerForm.isFormPosted
                ? registerForm.password.errorMessage
                : null,
          ),
          const SizedBox(height: 15),
          const SizedBox(height: 30),
          SizedBox(
              width: double.infinity,
              height: 60,
              child: ButtonLogin(
                text: '¡Registrarse!',
                onPressed: registerForm.isPosting
                    ? null
                    //: ref.read(loginFormProvider.notifier).onFormSubmit
                    : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref.read(registerFormProvider.notifier).onFormSubmit();
                      },
              )),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[400],
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //const Text('\n'),
              TextButton(
                  onPressed: () => context.goNamed(LoginScreen.name),
                  child: const Text('¡O pincha aquí si ya tienes cuenta!'))
            ],
          ),
        ],
      ),
    );
  }
}
