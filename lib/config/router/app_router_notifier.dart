import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterNotifierProvider = Provider((ref) {
  final notifier = GoRouterNotifier();
  ref.listen<AuthState>(
    authProvider,
    (_, state) => notifier.authStatus = state.authStatus,
    fireImmediately: true,
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

class GoRouterNotifier extends ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.checking;

  AuthStatus get authStatus => _authStatus;

  set authStatus(AuthStatus value) {
    if (_authStatus == value) return;
    _authStatus = value;
    notifyListeners();
  }
}
