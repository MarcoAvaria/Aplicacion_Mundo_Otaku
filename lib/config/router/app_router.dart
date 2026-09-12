import 'package:aplicacion_mundo_otaku/config/router/app_router_notifier.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/preview_received_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/preview_requested_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/received_chat_list.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/requested_chat_list.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/details_screen.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

final goRouterProvider = Provider((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);
  // final socketService = Get.find<SocketService>();
  return GoRouter(
    initialLocation: AppRoutes.initialLocation(Uri.base),
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
          path: AppRoutes.splash,
          name: SplashScreen.name,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.home,
          name: HomeScreen.name,
          builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: AppRoutes.login,
          name: LoginScreen.name,
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register,
          name: RegisterScreen.name,
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.products,
          name: ProductsScreen.name,
          builder: (context, state) => const ProductsScreen()),
      GoRoute(
          path: AppRoutes.discover,
          name: DiscoverScreen.name,
          builder: (context, state) => const DiscoverScreen()),
      GoRoute(
          path: AppRoutes.chatList,
          name: ChatListScreen.name,
          builder: (context, state) => const ChatListScreen()),
      GoRoute(
          path: AppRoutes.requestedList,
          name: RequestedListScreen.name,
          builder: (context, state) => const RequestedListScreen()),
      GoRoute(
          path: AppRoutes.receivedList,
          name: ReceivedListScreen.name,
          builder: (context, state) => const ReceivedListScreen()),
      GoRoute(
        path: AppRoutes.previewReceivedPattern,
        builder: (context, state) => PreviewReceivedScreen(
          chatExchangeId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: AppRoutes.previewRequestedPattern,
        builder: (context, state) => PreviewRequestedScreen(
          chatExchangeId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: AppRoutes.chatPattern,
        builder: (context, state) => ChatScreen(
          conversacionId: state.pathParameters['conversationId'] ?? 'no-id',
          miProductId: state.pathParameters['myProductId'] ?? 'no-id',
          otroProductId: state.pathParameters['otherProductId'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        name: PermisosScreen.name,
        builder: (context, state) => const PermisosScreen(),
      ),
      GoRoute(
        path: AppRoutes.pushDetailsPattern,
        builder: (context, state) => DetailsScreen(
            pushMessageId: state.pathParameters['messageId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.authStatus,
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.productPattern,
        builder: (context, state) => ProductScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: AppRoutes.otherProductPattern,
        builder: (context, state) => OtherProductScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
    ],
    redirect: (context, state) {
      final isGoingTo = state.matchedLocation;
      final authStatus = goRouterNotifier.authStatus;

      if (isGoingTo == AppRoutes.authStatus &&
          authStatus == AuthStatus.checking) {
        return null;
      }

      if (authStatus == AuthStatus.notAuthenticated) {
        if (isGoingTo == AppRoutes.login || isGoingTo == AppRoutes.register) {
          return null;
        }
        return AppRoutes.login;
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isGoingTo == AppRoutes.login ||
            isGoingTo == AppRoutes.register ||
            isGoingTo == AppRoutes.authStatus) {
          return AppRoutes.discover;
        }
      }

      return null;
    },
  );
});
