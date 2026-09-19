abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const products = '/productos';
  static const discover = '/discover';
  static const chatList = '/chatList';
  static const requestedList = '/requestedList';
  static const receivedList = '/receivedList';
  static const authStatus = '/splash_status';

  static const previewReceivedPattern = '/previewreceived/:id';
  static const previewRequestedPattern = '/previewrequested/:id';
  static const chatPattern =
      '/chatscreen/:conversationId/:myProductId/:otherProductId';
  static const productPattern = '/product/:id';
  static const otherProductPattern = '/otherproduct/:id';

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

  static String product(String id) => '/product/${Uri.encodeComponent(id)}';

  static String otherProduct(String id) =>
      '/otherproduct/${Uri.encodeComponent(id)}';
}
