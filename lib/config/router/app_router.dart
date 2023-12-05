import 'package:aplicacion_mundo_otaku/config/router/app_router_notifier.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/details_screen.dart';
import 'package:go_router/go_router.dart';
//import 'package:aplicacion_mundo_otaku/feautures/auth/presentation/screens/screens.dart';

final goRouterProvider = Provider((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
          path: '/',
          name: SplashScreen.name,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/home',
          name: HomeScreen.name,
          builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/login',
          name: LoginScreen.name,
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          name: RegisterScreen.name,
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/mangas',
          name: MangaScreen.name,
          builder: (context, state) => const MangaScreen()),
      GoRoute(
          path: '/productos',
          name: ProductsScreen.name,
          builder: (context, state) => const ProductsScreen()),
      GoRoute(
          path: '/discover',
          name: DiscoverScreen.name,
          builder: (context, state) => const DiscoverScreen()),
      /*
    GoRoute(
        path: '/configuracion',
        name: ConfigurationScreen.name,
        builder: (context, state) => const ConfigurationScreen()),
    */
      GoRoute(
          path: '/userList',
          name: UserListScreen.name,
          builder: (context, state) => const UserListScreen()),
      GoRoute(
        path: '/chatscreen/:id',
        //name: ChatScreen.name,
        builder: (context, state) => ChatScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
          //userId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: '/permisos',
        name: PermisosScreen.name,
        builder: (context, state) => const PermisosScreen(),
      ),
      GoRoute(
        path: '/push-details/:messageId',
        //name: PermisosScreen.name,
        builder: (context, state) => DetailsScreen(
            pushMessageId: state.pathParameters['messageId'] ?? ''),
      ),
      GoRoute(
        path: '/splash_status',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: '/otherproduct/:id',
        builder: (context, state) => OtherProductScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      /*GoRoute(
      path: '/users',
      builder: (context, state) => const ChatScreen(user: user)
    ),*/
    ],
    redirect: (context, state) {
      final isGoingTo = state.matchedLocation;
      final authStatus = goRouterNotifier.authStatus;

      if (isGoingTo == '/splash_status' && authStatus == AuthStatus.checking) {
        return null;
      }

      if (authStatus == AuthStatus.notAuthenticated) {
        if (isGoingTo == '/login' || isGoingTo == '/register') return null;
        return '/login';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isGoingTo == '/login' ||
            isGoingTo == '/register' ||
            isGoingTo == '/splash_status') {
          //return '/mangas';
          return '/discover';
        }
      }

      //print(state);
      //print(state.matchedLocation);
      //return '/login';
      return null;
    },
  );
});
