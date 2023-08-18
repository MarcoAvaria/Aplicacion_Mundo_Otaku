//import 'package:aplicacion_mundo_otaku/screens/mangas_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/configuration_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/login_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/mangas_screen.dart';
import 'package:flutter/material.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  //runApp(const MyApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  //const MyApp({ Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundo Otaku - Betta',
      debugShowCheckedModeBanner: false,
      initialRoute: "splash",
      
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.purple[200],
      ),
      
      routes: {
        "splash":(context) => const SplashScreen(),
        "home":(context) => const HomeScreen(),
        "login": (context) => LoginScreen(),
        "mangas":(context) => const MangaScreen(),
        "configuracion":(context) => const ConfigurationScreen(),
      },
      //home: const MangaScreen(),
      //home: Container(),
    );
  }
}