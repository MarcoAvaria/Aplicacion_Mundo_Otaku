import 'package:flutter/material.dart';
import 'package:aplicacion_mundo_otaku/config/router/app_router.dart';
import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_mundo_otaku/presentation/providers/chat_provider.dart';
import 'package:aplicacion_mundo_otaku/presentation/providers/discover_provider.dart';
//import 'package:provider/provider.dart';
//import 'package:dcdg/dcdg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider() ),
        ChangeNotifierProvider(lazy: false, create: (_) => DiscoverProvider()..loadNextPage() )
      ],
    
    child: MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme(selectedColor: 0).getTheme(),
      )
    );
  }
}
