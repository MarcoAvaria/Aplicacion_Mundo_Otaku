import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';
import 'package:aplicacion_mundo_otaku/feautures/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  
  static const String name = 'register_screen';

  RegisterScreen({super.key});

  //Controladores de edición de texto
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Iniciar sesión
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    //const icon = Icon( Icons.lock, size: 50);

    var text = Text(
      '¿Qué esperas? ¡Crea tu cuenta ahora!',
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
    );

    var textoSinRegistro = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes contraseña?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(width: 4),
        InkWell(
          child: const Text(
            '¡Pincha aquí para ingresar!',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            context.goNamed(LoginScreen.name);
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
              text,
              const SizedBox(height: 30),
              NewWidgetMiCampoTextoRecover( varTextCtrl: usernameController, hintText: "Nombre completo", darkText: false),
              const SizedBox(height: 10),
              NewWidgetMiCampoTextoRecover( varTextCtrl: passwordController, hintText: "Correo electrónico", darkText: true),
              const SizedBox(height: 10),
              NewWidgetMiCampoTextoRecover( varTextCtrl: passwordController, hintText: "Crea tu contraseña", darkText: true),
              const SizedBox(height: 10),
              NewWidgetMiCampoTextoRecover( varTextCtrl: passwordController, hintText: "Vuelva a ingresar la contraseña", darkText: true),
              const SizedBox(height: 15),

              ButtonLogin.myOwnMethodElevatedButton( context, usernameController , passwordController ),

              const SizedBox(height: 15),
              continuarconTexto, const SizedBox(height: 30),
              const GoogleOutlookSignUp(),
              const SizedBox(height: 15),
              textoSinRegistro
            ],
          ),
        ),
      ),
    );
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

class NewWidgetMiCampoTextoRecover extends StatelessWidget {
  final String hintText;
  final bool darkText;

  const NewWidgetMiCampoTextoRecover({
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
