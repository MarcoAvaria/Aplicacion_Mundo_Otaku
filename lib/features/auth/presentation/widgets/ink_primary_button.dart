import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';

/// Botón principal del acceso y el registro, con la sombra dura impresa.
///
/// Declara `button: true` de forma explícita. Un `InkWell` suelto no basta: el
/// recorrido Playwright localiza el botón de acceso por su rol con el nombre
/// "Iniciar sesión", y sin esa declaración no aparece como botón en el árbol
/// de accesibilidad.
///
/// Declara además `onTap`. No es redundante con el `InkWell`: `excludeSemantics`
/// descarta el subárbol, y con él la acción de pulsar que el `InkWell` aportaba.
/// El botón quedaba anunciándose como botón **sin ninguna acción disponible**.
/// Se detectó el 2026-09-22 leyendo el árbol de accesibilidad real en un
/// dispositivo Android, donde el nodo aparecía con `clickable="false"` mientras
/// que las entradas del menú lateral sí eran accionables.
class InkPrimaryButton extends StatelessWidget {
  const InkPrimaryButton({
    super.key,
    required this.tokens,
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final InkTokens tokens;
  final String label;

  /// Mientras la petición viaja: rueda en vez de texto, y el botón se anuncia
  /// como deshabilitado.
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isBusy,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Material(
          color: tokens.accent,
          shape: Border.all(color: tokens.ink, width: 2.5),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: isBusy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(tokens.onAccent),
                      ),
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: tokens.onAccent,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
