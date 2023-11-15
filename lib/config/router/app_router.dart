import 'package:aplicacion_mundo_otaku/config/router/app_router_notifier.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/product_screen.dart';
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
        path: '/discover',
        name: ProductsScreen.name,
        builder: (context, state) => const ProductsScreen()),
    GoRoute(
        path: '/configuracion',
        name: ConfigurationScreen.name,
        builder: (context, state) => const ConfigurationScreen()),
    GoRoute(
        path: '/userList',
        name: UserListScreen.name,
        builder: (context, state) => const UserListScreen()),
    GoRoute(
        path: '/users',
        name: ChatScreen.name,
        builder: (context, state) {
          final User user = state.extra as User;
          return ChatScreen(user: user);
        }),
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
      builder: (context, state) =>
          DetailsScreen(pushMessageId: state.pathParameters['messageId'] ?? ''),
    ),
    GoRoute(
      path: '/splash_status',
      //name: CheckAuthStatusScreen.name,
      builder: (context, state) => const CheckAuthStatusScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductScreen(
        productId: state.pathParameters['id'] ?? 'no-id',
      ),
    ),
    /*GoRoute(
      path: '/users',
      builder: (context, state) => const ChatScreen(user: user)
    ),*/
  ],

  redirect: (context, state){
    
    final isGoingTo = state.matchedLocation;
    final authStatus = goRouterNotifier.authStatus;

    if ( isGoingTo == '/splash_status' && authStatus == AuthStatus.checking) return null;

    if ( authStatus == AuthStatus.notAuthenticated) { 
      if( isGoingTo == '/login' || isGoingTo =='/register') return null;
      return '/login';
    }

    if ( authStatus == AuthStatus.authenticated ) {
      if ( isGoingTo == '/login' || isGoingTo == '/register' || isGoingTo == '/splash_status') { 
        return '/mangas';
      }
    }

    

    //print(state);
    //print(state.matchedLocation);
    //return '/login';
    return null;
  },
  
  );

});