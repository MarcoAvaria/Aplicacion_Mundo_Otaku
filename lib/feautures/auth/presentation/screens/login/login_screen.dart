//import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/providers/register_form_provider.dart';
//import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/feautures/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  static const String name = 'login_screen';

  const LoginScreen({super.key});

  // Iniciar sesión
  void signUserIn() {}

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
                        child: _LoginForm(),
                      )
                    ]))));
  }
}

class GoogleOutlookSignIn extends StatelessWidget {
  const GoogleOutlookSignIn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        //Boton Google
        SquareTile(imagePath: 'assets/google_image.png'),

        SizedBox(width: 25),

        //Boton Outlook
        SquareTile(imagePath: 'assets/outlook_image.png'),
      ],
    );
  }
}

class NewWidgetRecuperarPass extends StatelessWidget {
  const NewWidgetRecuperarPass({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "¿Olvidaste la contraseña?",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends ConsumerWidget {
  _LoginForm();

  //Controladores de edición de texto
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final textStyles = Theme.of(context).textTheme;

    final loginForm = ref.watch(loginFormProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          //Text('Login', style: textStyles.titleLarge ),
          Text(
            '¡Bienvenid@! Te hemos extrañado :(',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          MyFieldText(
              varTextCtrl: usernameController,
              onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
              errorMessage: loginForm.isFormPosted ?
                loginForm.email.errorMessage : null,
              label: "Nombre de usuari@",
              darkText: false),

          // const CustomTextFormField(
          //   label: 'Correo',
          //   keyboardType: TextInputType.emailAddress,
          // ),
          const SizedBox(height: 15),

          // const CustomTextFormField(
          //   label: 'Contraseña',
          //   obscureText: true,
          // ),

          MyFieldText(
            varTextCtrl: passwordController,
            label: "Contraseña",
            darkText: true,
            onChanged: ref.read(loginFormProvider.notifier).onPasswordChanged,
            errorMessage: loginForm.isFormPosted ?
                loginForm.password.errorMessage : null,
          ),
          const SizedBox(height: 15),
          const NewWidgetRecuperarPass(),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ButtonLogin(
              text: 'Iniciar sesión', 
              onPressed: () {
                ref.read(loginFormProvider.notifier).onFormSubmit();
              },
              ),
          ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'O puede ingresar con...',
                    style: TextStyle(color: Colors.grey[700]),
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

          const GoogleOutlookSignIn(),

          //const Spacer(flex: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?'),
              TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Crea una aquí'))
            ],
          ),
          //const Spacer(flex: 1),
        ],
      ),
    );
  }
}
