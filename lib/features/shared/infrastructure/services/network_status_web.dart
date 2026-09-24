// `dart:html` quedó obsoleta: la reemplazan `package:web` y `dart:js_interop`.
// El cambio no es solo de nombre. Allí los eventos llegaban como `Stream` de
// Dart (`window.onOnline`), y aquí hay que registrar y dar de baja los oyentes
// a mano, guardando la misma referencia `JSFunction` que se pasó al registrar:
// si se convirtiera dos veces con `.toJS` saldrían dos objetos distintos y
// `removeEventListener` no encontraría cuál quitar, dejando el oyente vivo.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Stream<bool> get networkStatusChanges => Stream<bool>.multi((controller) {
      final alConectar = ((web.Event _) => controller.add(true)).toJS;
      final alDesconectar = ((web.Event _) => controller.add(false)).toJS;

      web.window.addEventListener('online', alConectar);
      web.window.addEventListener('offline', alDesconectar);

      controller.onCancel = () {
        web.window.removeEventListener('online', alConectar);
        web.window.removeEventListener('offline', alDesconectar);
      };
    });

bool get isNetworkOnline => web.window.navigator.onLine;
