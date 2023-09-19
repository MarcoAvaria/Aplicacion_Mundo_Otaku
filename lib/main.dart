import 'package:flutter/material.dart';
import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:aplicacion_mundo_otaku/config/router/app_router.dart';

import 'package:aplicacion_mundo_otaku/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  
  runApp((
    MultiBlocProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider() ),
        ChangeNotifierProvider(lazy: false, create: (_) => DiscoverProvider()..loadNextPage() ),
        BlocProvider(
          create: (_) => NotificationsBloc(),
        ),
      ],
      child: const MyApp(),
    )
  ));

  //runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /*return MultiBlocProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider() ),
        ChangeNotifierProvider(lazy: false, create: (_) => DiscoverProvider()..loadNextPage() ),
        BlocProvider(
          create: (_) => NotificationsBloc(),
        ),
      ],
    
    child: MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme(selectedColor: 0).getTheme(),
      )
    );*/
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme(selectedColor: 0).getTheme(),
    );
  }
}
