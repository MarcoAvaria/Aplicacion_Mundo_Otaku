import 'package:aplicacion_mundo_otaku/components/mi_boton.dart';
import 'package:aplicacion_mundo_otaku/components/mi_campotexto.dart';
import 'package:aplicacion_mundo_otaku/components/square_tile.dart';
import 'package:aplicacion_mundo_otaku/screens/mangas_screen.dart';
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
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // logo
              const Icon(
                Icons.lock,
                size: 100,
              ),

              const SizedBox(height: 30),

              //bienvenido!
              Text(
                '¡Bienvenid@! Te hemos extrañado :(',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // texto de user
              MiCampoTexto(
                controller: usernameController,
                hintText: 'Nombre de usuario',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // campo de pass
              MiCampoTexto(
                controller: passwordController,
                hintText: "Contraseña",
                obscureText: true,
              ),

              const SizedBox(height: 10),

              // olvidaste la pass?
              Padding(
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
              ),

              const SizedBox(height: 25),

              /*// botón para ingresar
                MiBoton(
                  onTap: signUserIn, //11:37
                ),
                */

              ElevatedButton(
                onPressed: () {
                  // Validar el usuario y la contraseña aquí
                  //String username = usernameController.text;
                  //String password = passwordController.text;

                  if (usernameController == '' && passwordController == '') {
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
                      MaterialPageRoute(builder: (context) => MangaScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Iniciar sesión'),
              ),

              const SizedBox(height: 50),

              // o continuar con...
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

              const SizedBox(height: 50),

              // Botones: Google & Outlook
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Boton Google
                  SquareTile(imagePath: 'assets/google_image.png'),

                  SizedBox(width: 25),

                  //Boton Outlook
                  //SquareTile(imagePath: 'lib/images/outlook_image.png'),
                  SquareTile(imagePath: 'assets/outlook_image.png'),
                ],
              ),

              const SizedBox(height: 50),

              // "¿No tienes registro?"
              Row(
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
