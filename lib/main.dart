//import 'package:aplicacion_mundo_otaku/screens/mangas_screen.dart';
import 'package:aplicacion_mundo_otaku/screens/configuration_screen.dart';
import 'package:aplicacion_mundo_otaku/screens/login_screen.dart';
import 'package:aplicacion_mundo_otaku/screens/mangas_screen.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

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
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      initialRoute: "splash",
      routes: {
        "splash":(context) => SplashScreen(),
        "home":(context) => HomeScreen(),
        "login": (context) => LoginScreen(),
        "mangas":(context) => MangaScreen(),
        "configuracion":(context) => ConfigurationScreen(),
      },
      //home: const MangaScreen(),
      //home: Container(),
    );
  }
}