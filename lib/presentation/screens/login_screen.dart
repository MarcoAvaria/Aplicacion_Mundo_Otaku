//import 'package:aplicacion_mundo_otaku/components/mi_boton.dart';
import 'package:aplicacion_mundo_otaku/components/mi_campotexto.dart';
import 'package:aplicacion_mundo_otaku/components/square_tile.dart';
//import 'package:aplicacion_mundo_otaku/presentation/screens/chat/user_list_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/mangas_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //Controladores de edición de texto
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Iniciar sesión
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    const icon = Icon(
      Icons.lock,
      size: 100,
    );

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
        const Text(
          '¡Puedes crear una ahora!',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // logo
              icon,

              const SizedBox(height: 30),

              //bienvenido!
              text,

              const SizedBox(height: 25),

              // texto de user
              NewWidgetMiCampoTexto(
                  variabletextController: usernameController,
                  hintText: "Nombre de usuari@",
                  obscureText: false),

              const SizedBox(height: 10),

              // campo de pass
              NewWidgetMiCampoTexto(
                  variabletextController: passwordController,
                  hintText: "Contraseña",
                  obscureText: true),

              const SizedBox(height: 10),

              // olvidaste la pass?
              const NewWidgetRecuperarPass(),

              const SizedBox(height: 25),

              NewWidgetElevatedButton(
                  usernameController: usernameController,
                  passwordController: passwordController),

              const SizedBox(height: 50),

              // o continuar con...
              continuarconTexto,

              const SizedBox(height: 50),

              // Botones: Google & Outlook
              const GoogleOutlookSignIn(),

              const SizedBox(height: 50),

              // "¿No tienes registro?"
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

class NewWidgetElevatedButton extends StatelessWidget {
  const NewWidgetElevatedButton({
    super.key,
    required this.usernameController,
    required this.passwordController,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Validar el usuario y la contraseña aquí
        //String username = usernameController.text;
        //String password = passwordController.text;

        if (usernameController.text == "" && passwordController.text == "") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Usuario o contraseña incorrectos.'),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MangaScreen()),
            //MaterialPageRoute(builder: (context) => const ChatScreen()),
            //MaterialPageRoute(builder: (context) => const UserListScreen()),
            //MaterialPageRoute(builder: (context) => const AllChatsScreen()),
            (route) => false,
          );
        }
      },
      child: const Text('Iniciar sesión'),
    );
  }
}

class NewWidgetMiCampoTexto extends StatelessWidget {
  final String hintText;
  final bool obscureText;

  const NewWidgetMiCampoTexto({
    super.key,
    required this.variabletextController,
    required this.hintText,
    required this.obscureText,
  });

  final TextEditingController variabletextController;

  @override
  Widget build(BuildContext context) {
    return MiCampoTexto(
      controller: variabletextController,
      hintText: hintText,
      obscureText: obscureText,
    );
  }
}
