import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterNotifierProvider = Provider((ref) {
  final authState = ref.read(authProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return GoRouterNotifier(authNotifier, authState.authStatus);
});

class GoRouterNotifier extends ChangeNotifier {
  final AuthNotifier _authNotifier;

  AuthStatus _authStatus;

  GoRouterNotifier(this._authNotifier, this._authStatus) {
    _authNotifier.addListener((state) {
      authStatus = state.authStatus;
    });
  }

  AuthStatus get authStatus => _authStatus;

  set authStatus(AuthStatus value) {
    _authStatus = value;
    notifyListeners();
  }
}
