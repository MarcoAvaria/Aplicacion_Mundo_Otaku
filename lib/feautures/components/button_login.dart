import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../feautures/auth/presentation/screens/discover/mangas_screen.dart';

class ButtonLogin {
  static ElevatedButton myOwnMethodElevatedButton(BuildContext context,
      TextEditingController uCtrl, TextEditingController pCtrl) {
    return ElevatedButton(
      onPressed: () {
        // Validar el usuario y la contraseña aquí
        //String uCtrl = u.text;
        //String pCtrl = p.text;
        if (uCtrl.text == "" && pCtrl.text == "") {
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
        }
        if (uCtrl.text == "Marco" && pCtrl.text == "123") {
          /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MangaScreen()),
            (route) => false,
          );*/
          context.goNamed( MangaScreen.name );
        }
      },
      child: const Text('Iniciar sesión'),
    );
  }
}
