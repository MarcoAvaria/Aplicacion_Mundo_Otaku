import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Verificación de sesión en la dirección "Tinta y Neón".
///
/// Es una pantalla de tránsito: se ve mientras se comprueba el token guardado y
/// el router decide a dónde ir. Por eso se mantiene deliberadamente liviana, sin
/// imágenes ni animaciones propias; lo único que cambia respecto de
/// `CheckAuthStatusScreen`, que queda intacta, es que usa el papel y el acento
/// de la marca en vez de los colores por defecto de Material.
///
/// Suma además un anuncio para lectores de pantalla. La original mostraba una
/// rueda sin ningún texto, así que no decía nada sobre lo que estaba pasando.
class InkCheckAuthStatusScreen extends ConsumerWidget {
  const InkCheckAuthStatusScreen({super.key});

  static const String name = 'ink_splash_status';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = InkTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.paper,
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Comprobando tu sesión',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MUNDO OTAKU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: tokens.halftone,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cambia',
                  style: AppFonts.displayStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    letterSpacing: -0.6,
                    color: tokens.text,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(tokens.halftone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
