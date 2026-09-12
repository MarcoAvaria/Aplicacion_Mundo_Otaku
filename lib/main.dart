import 'package:aplicacion_mundo_otaku/features/shared/widgets/chat/chat_controller.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';
// import 'package:aplicacion_mundo_otaku/features/auth/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initEnvironment();
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // await NotificationsBloc.initializeFCM();

  // Registra ChatController
  Get.put(ChatController());

  runApp(const ProviderScope(
    child: MainApp(),
  ));
  //runApp(const MyApp());
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(goRouterProvider);

    //print( Enviroment.apiUrl );
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme(selectedColor: 0).getTheme(),
    );
  }
}
