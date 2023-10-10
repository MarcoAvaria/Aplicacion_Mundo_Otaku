import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';
import 'package:aplicacion_mundo_otaku/feautures/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  
  static const String name = 'login_screen';

  LoginScreen({super.key});

  //Controladores de edición de texto
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Iniciar sesión
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    const icon = Icon( Icons.lock, size: 50);

    var text = Text(
      '¡Bienvenid@! Te hemos extrañado :(',
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 16,
      ),
    );

    var continuarconTexto = Padding(
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
    );

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

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //mainAxisSize: D,
            children: [
              const SizedBox(height: 50),
              icon,
              const SizedBox(height: 30),
              text,
              const SizedBox(height: 25),
              NewWidgetMiCampoTexto( varTextCtrl: usernameController, hintText: "Nombre de usuari@", darkText: false),
              const SizedBox(height: 10),
              NewWidgetMiCampoTexto( varTextCtrl: passwordController, hintText: "Contraseña", darkText: true),
              const SizedBox(height: 10),
              // olvidaste la pass?
              const NewWidgetRecuperarPass(),
              const SizedBox(height: 25),


              ButtonLogin.myOwnMethodElevatedButton( context, usernameController , passwordController ),

              const SizedBox(height: 50),
              continuarconTexto, const SizedBox(height: 50),
              const GoogleOutlookSignIn(),
              const SizedBox(height: 50),
              textoSinRegistro
            ],
          ),
        ),
      ),
    );
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
        //SquareTile(imagePath: 'lib/images/outlook_image.png'),
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

class NewWidgetMiCampoTexto extends StatelessWidget {
  final String hintText;
  final bool darkText;

  const NewWidgetMiCampoTexto({
    super.key,
    required this.varTextCtrl,
    required this.hintText,
    required this.darkText,
  });

  final TextEditingController varTextCtrl;

  @override
  Widget build(BuildContext context) {
    return MiCampoTexto(
      controller: varTextCtrl,
      hintText: hintText,
      obscureText: darkText,
    );
  }
}
