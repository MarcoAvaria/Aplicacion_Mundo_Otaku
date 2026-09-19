// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

Stream<bool> get networkStatusChanges => Stream<bool>.multi((controller) {
      final onlineSubscription =
          html.window.onOnline.listen((_) => controller.add(true));
      final offlineSubscription =
          html.window.onOffline.listen((_) => controller.add(false));

      controller.onCancel = () async {
        await onlineSubscription.cancel();
        await offlineSubscription.cancel();
      };
    });

bool get isNetworkOnline => html.window.navigator.onLine ?? true;
