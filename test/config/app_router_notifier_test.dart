import 'package:aplicacion_mundo_otaku/config/router/app_router_notifier.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoRouterNotifier notifies only when authentication status changes', () {
    final notifier = GoRouterNotifier();
    var notifications = 0;
    notifier.addListener(() => notifications += 1);

    notifier.authStatus = AuthStatus.checking;
    notifier.authStatus = AuthStatus.authenticated;
    notifier.authStatus = AuthStatus.authenticated;

    expect(notifier.authStatus, AuthStatus.authenticated);
    expect(notifications, 1);
  });
}
