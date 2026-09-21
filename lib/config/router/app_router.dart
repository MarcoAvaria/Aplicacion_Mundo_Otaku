import 'package:aplicacion_mundo_otaku/config/router/app_router_notifier.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/login/ink_login_screen.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/register/ink_register_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_exchange_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/ink_exchange_preview_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/received_chat_list.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/requested_chat_list.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

final goRouterProvider = Provider((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);
  return GoRouter(
    refreshListenable: goRouterNotifier,
    routes: [
      GoRoute(
          path: AppRoutes.splash,
          redirect: (context, state) => AppRoutes.authStatus),
      GoRoute(
          path: AppRoutes.login,
          name: LoginScreen.name,
          builder: (context, state) => const InkLoginScreen()),
      GoRoute(
          path: AppRoutes.register,
          name: RegisterScreen.name,
          builder: (context, state) => const InkRegisterScreen()),
      GoRoute(
          path: AppRoutes.products,
          name: ProductsScreen.name,
          builder: (context, state) => const InkProductsScreen()),
      GoRoute(
          path: AppRoutes.discover,
          name: DiscoverScreen.name,
          builder: (context, state) => const InkDiscoverScreen()),
      GoRoute(
          path: AppRoutes.chatList,
          name: ChatListScreen.name,
          builder: (context, state) => const InkChatListScreen()),
      GoRoute(
          path: AppRoutes.requestedList,
          name: RequestedListScreen.name,
          builder: (context, state) =>
              const InkExchangeListScreen(inbox: ExchangeInbox.sent)),
      GoRoute(
          path: AppRoutes.receivedList,
          name: ReceivedListScreen.name,
          builder: (context, state) =>
              const InkExchangeListScreen(inbox: ExchangeInbox.received)),
      GoRoute(
        path: AppRoutes.previewReceivedPattern,
        builder: (context, state) => InkExchangePreviewScreen(
          chatExchangeId: state.pathParameters['id'] ?? 'no-id',
          inbox: ExchangeInbox.received,
        ),
      ),
      GoRoute(
        path: AppRoutes.previewRequestedPattern,
        builder: (context, state) => InkExchangePreviewScreen(
          chatExchangeId: state.pathParameters['id'] ?? 'no-id',
          inbox: ExchangeInbox.sent,
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
        path: AppRoutes.authStatus,
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.productPattern,
        builder: (context, state) => InkProductScreen(
          productId: state.pathParameters['id'] ?? 'no-id',
        ),
      ),
      GoRoute(
        path: AppRoutes.otherProductPattern,
        builder: (context, state) => InkOtherProductScreen(
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
