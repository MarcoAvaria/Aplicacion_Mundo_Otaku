import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:aplicacion_mundo_otaku/config/theme/app_theme.dart';
import 'package:aplicacion_mundo_otaku/config/router/app_router.dart';

import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/providers/chat_provider.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/providers/discover_provider.dart';
//import 'package:dcdg/dcdg.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationsBloc.initializeFCM();

  runApp((MultiBlocProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(
          lazy: false, create: (_) => DiscoverProvider()..loadNextPage()),
      BlocProvider(
        create: (_) => NotificationsBloc(),
      ),
    ],
    //child: const ProviderScope(child: MyApp())
    child: const MyApp(),
  )));

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
      builder: (context, child) =>
          HandleNotificationInteractions(child: child!),
    );
  }
}

class HandleNotificationInteractions extends StatefulWidget {
  final Widget child;
  const HandleNotificationInteractions({super.key, required this.child});

  @override
  State<HandleNotificationInteractions> createState() =>
      _HandleNotificationInteractionsState();
}

class _HandleNotificationInteractionsState
    extends State<HandleNotificationInteractions> {
  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    context.read<NotificationsBloc>().handleRemoteMessage(message);

    final messageId =
        message.messageId?.replaceAll(':', '').replaceAll('%', '');

    // if (message.data['type'] == 'chat') {
    //   Navigator.pushNamed(context, '/chat',
    //     arguments: ChatArguments(message),
    //   );
    // }

    appRouter.push('/push-details/$messageId');
  }

  @override
  void initState() {
    super.initState();

    // Run code required to handle interacted messages in an async function
    // as initState() must not be async
    setupInteractedMessage();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}