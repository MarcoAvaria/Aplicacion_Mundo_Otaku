import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';

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
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[50],
        foregroundColor: Colors.purple[800], 
        side: BorderSide(color: Colors.purpleAccent.shade200, width: 0.10)
        //side: BorderSide(color: Colors.purpleAccent[300], width: 3)
      ),
      child: 
        const Text('Iniciar sesión'),
    );
  }
}
