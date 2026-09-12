abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const products = '/productos';
  static const discover = '/discover';
  static const chatList = '/chatList';
  static const requestedList = '/requestedList';
  static const receivedList = '/receivedList';
  static const permissions = '/permisos';
  static const authStatus = '/splash_status';

  static const previewReceivedPattern = '/previewreceived/:id';
  static const previewRequestedPattern = '/previewrequested/:id';
  static const chatPattern =
      '/chatscreen/:conversationId/:myProductId/:otherProductId';
  static const pushDetailsPattern = '/push-details/:messageId';
  static const productPattern = '/product/:id';
  static const otherProductPattern = '/otherproduct/:id';

  static String initialLocation(Uri browserUri) {
    final fragment = browserUri.fragment;
    if (fragment.startsWith('/')) {
      return fragment;
    }

    final path = browserUri.path;
    if (path.isEmpty || path == '/') return login;
    return browserUri.hasQuery ? '$path?${browserUri.query}' : path;
  }

  static String previewReceived(String id) =>
      '/previewreceived/${Uri.encodeComponent(id)}';

  static String previewRequested(String id) =>
      '/previewrequested/${Uri.encodeComponent(id)}';

  static String chat({
    required String conversationId,
    required String myProductId,
    required String otherProductId,
  }) =>
      '/chatscreen/${Uri.encodeComponent(conversationId)}'
      '/${Uri.encodeComponent(myProductId)}'
      '/${Uri.encodeComponent(otherProductId)}';

  static String pushDetails(String messageId) =>
      '/push-details/${Uri.encodeComponent(messageId)}';

  static String product(String id) => '/product/${Uri.encodeComponent(id)}';

  static String otherProduct(String id) =>
      '/otherproduct/${Uri.encodeComponent(id)}';
}
