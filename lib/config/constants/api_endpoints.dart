abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authLogout = '/auth/logout';
  static const authStatus = '/auth/check-auth-status';

  static const products = '/products';
  static const myProducts = '/products/mine';
  static const productImages = '/files/product';

  static const chatExchanges = '/chat-exchanges';

  static String product(String id) => '$products/${Uri.encodeComponent(id)}';

  static String productImage(String imageName) =>
      '$productImages/${Uri.encodeComponent(imageName)}';

  static String chatExchange(String id) =>
      '$chatExchanges/${Uri.encodeComponent(id)}';

  static String chatExchangeStatus(String id) => '${chatExchange(id)}/status';

  static String chatExchangesForUser(String userId) =>
      '$chatExchanges/user/${Uri.encodeComponent(userId)}';
}
