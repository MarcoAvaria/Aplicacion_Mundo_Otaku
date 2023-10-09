import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/details_screen.dart';
import 'package:go_router/go_router.dart';

import '../../feautures/auth/presentation/screens/screens.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: SplashScreen.name,
      builder: (context, state) => const SplashScreen()
    ),
    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen()
    ),
    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => LoginScreen()
    ),
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      builder: (context, state) => const RegisterScreen()
    ),
    GoRoute(
      path: '/mangas',
      name: MangaScreen.name,
      builder: (context, state) => const MangaScreen()
    ),
    GoRoute(
      path: '/discover',
      name: DiscoverScreen.name,
      builder: (context, state) => const DiscoverScreen()
    ),
    GoRoute(
      path: '/configuracion',
      name: ConfigurationScreen.name,
      builder: (context, state) => const ConfigurationScreen()
    ),
    GoRoute(
      path: '/userList',
      name: UserListScreen.name,
      builder: (context, state) => const UserListScreen()
    ),
    GoRoute(
      path: '/users',
      name: ChatScreen.name,
      builder: (context, state) { 
        final User user = state.extra as User;
        return ChatScreen(user: user);
      }
    ),
    GoRoute(
      path: '/cubits',
      name: CubitCounterScreen.name,
      builder: (context, state) => const CubitCounterScreen(),
    ),
    GoRoute(
      path: '/counter-bloc',
      name: BlocCounterScreen.name,
      builder: (context, state) => const BlocCounterScreen(),
    ),
    GoRoute(
      path: '/permisos',
      name: PermisosScreen.name,
      builder: (context, state) => const PermisosScreen(),
    ),
    GoRoute(
      path: '/push-details/:messageId',
      //print('${ messageId }'),
      //name: PermisosScreen.name,
      builder: (context, state) => DetailsScreen( pushMessageId: state.pathParameters['messageId'] ?? ''),
    ),
    /*GoRoute(
      path: '/users',
      builder: (context, state) => const ChatScreen(user: user)
    ),*/
  ]
);