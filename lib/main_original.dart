//MAIN DEPRECATED FOR THE MOMENT

//import 'package:aplicacion_mundo_otaku/screens/mangas_screen.dart';
import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/configuration/configuration_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/home/login_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/discover/mangas_screen.dart';
import 'package:flutter/material.dart';

import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/home/splash_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key}); //const MyApp({ Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mundo Otaku - Betta',
      debugShowCheckedModeBanner: false,
      initialRoute: "splash",
      
      theme: AppTheme( selectedColor: 0).theme(),
      
      routes: {
        "splash":(context) => const SplashScreen(),
        "home":(context) => const HomeScreen(),
        "login": (context) => LoginScreen(),
        "mangas":(context) => const MangaScreen(),
        "configuracion":(context) => const ConfigurationScreen(),
        //"chat":(context) => const ChatScreen(),
        //"allchats":(context) => const AllChatsScreen(),
      },
      //home: const MangaScreen(),
      //home: Container(),
    );
  }
}