import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';
import 'package:aplicacion_mundo_otaku/feautures/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  static const String name = 'register_screen';

  const RegisterScreen({super.key});

  // Iniciar sesión
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {

    var textoSinRegistro = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(width: 4),
        InkWell(
          child: const Text(
            '¡Puedes crear una ahora!',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            context.goNamed(RegisterScreen.name);
          },
        ),
      ],
    );

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
                        height: size.height - 130, // 80 los dos sizebox y 100 el ícono
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

class GoogleOutlookSignUp extends StatelessWidget {
  const GoogleOutlookSignUp({
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
        //SquareTile(imagePath: 'lib/images/outlook_image.png'),
        SquareTile(imagePath: 'assets/outlook_image.png'),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  _LoginForm();
  
  //Controladores de edición de texto
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final secondPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    //final textStyles = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          //Text('Login', style: textStyles.titleLarge ),
          Text(
            '¿Qué esperas? ¡Crea tu cuenta ahora!',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          MyFieldText( varTextCtrl: usernameController, label: "Nombre completo", darkText: false),
          const SizedBox(height: 10),
          MyFieldText( varTextCtrl: emailController, label: "Correo electrónico", darkText: true),
          const SizedBox(height: 10),
          MyFieldText( varTextCtrl: passwordController, label: "Crea tu contraseña", darkText: true),
          const SizedBox(height: 10),
          MyFieldText( varTextCtrl: secondPasswordController, label: "Vuelva a ingresar la contraseña", darkText: true),

          const SizedBox(height: 30),

          const SizedBox(
            width: double.infinity,
            height: 60,
            // child: ButtonLogin(
            //     text: 'Crea tu cuenta',
            //     onPressed: ()),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
                    'Puedes crear una cuenta con:',
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

          const SizedBox(height: 20),

          const GoogleOutlookSignIn(),

          //const Spacer(flex: 2),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //const Text('\n'),
              TextButton(
                  onPressed: () => context.goNamed(LoginScreen.name),
                  child: const Text('¡O pincha aquí si ya tienes cuenta!'))
            ],

          ),
          //const Spacer(flex: 1),
        ],
      ),
    );
  }
}
