import 'package:go_router/go_router.dart';

import '../../presentation/screens/screens.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [

    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => LoginScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MangaScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ConfigurationScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const UserListScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen()
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen()
    ),
  ]
);