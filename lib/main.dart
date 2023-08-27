import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:aplicacion_mundo_otaku/presentation/providers/chat_provider.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/chat/user_list_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/chat/chat_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/configuration_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/login_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/discover/mangas_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider() )
      ],
      child: MaterialApp(
          title: 'Mundo Otaku - Betta',
          debugShowCheckedModeBanner: false,
          initialRoute: "splash",
          theme: AppTheme(selectedColor: 0).theme(),
          onGenerateRoute: (settings) {
            if (settings.name == "users") {
              // Extract the arguments that were passed to this route
              final User user = settings.arguments
                  as User; // Replace User with your actual user class
    
              // Create and return the screen with the extracted arguments
              return MaterialPageRoute(
                builder: (context) => ChatScreen(user: user),
              );
            } else if (settings.name == "home") {
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            } else if (settings.name == "login") {
              return MaterialPageRoute(
                builder: (context) => LoginScreen(),
              );
            } else if (settings.name == "mangas") {
              return MaterialPageRoute(
                builder: (context) => const MangaScreen(),
              );
            } else if (settings.name == "configuracion") {
              return MaterialPageRoute(
                builder: (context) => const ConfigurationScreen(),
              );
            } else if (settings.name == "userList") {
              return MaterialPageRoute(
                builder: (context) => const UserListScreen(),
              );
            } else if (settings.name == "splash") {
              return MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              );
            }
            // Handle other routes here
    
            return null; // Return null if the route is not handled
          }),
    );
  }
}
