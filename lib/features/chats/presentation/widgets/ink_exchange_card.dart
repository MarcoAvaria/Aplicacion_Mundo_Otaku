import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';

/// Un intercambio contado como doble página: lo que entregas y lo que recibes,
/// con la flecha de intercambio entre medio.
///
/// La usan la bandeja de solicitudes y la lista de chats, que muestran lo mismo
/// en distintos momentos del flujo.
class InkExchangeCard extends StatelessWidget {
  const InkExchangeCard({
    super.key,
    required this.tokens,
    required this.kicker,
    required this.number,
    required this.theirs,
    required this.mine,
    required this.actionLabel,
    required this.tiltDegrees,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.badgeInset = defaultBadgeInset,
  });

  final InkTokens tokens;

  /// Texto de la cinta superior: "TE PROPONEN", "EN CURSO"…
  final String kicker;
  final String number;

  /// El producto de la otra persona, el que recibes.
  final Product theirs;

  /// El propio, cuando alcanzó a cargarse.
  final Product? mine;
  final String actionLabel;
  final String? subtitle;
  final double tiltDegrees;
  final VoidCallback onTap;

  /// Sello opcional pegado a la esquina superior derecha, como una calcomanía.
  ///
  /// Va dentro de la rotación para que se incline junto con la tarjeta, y
  /// sobresale del borde para no tapar nada de la cinta superior.
  final Widget? badge;

  /// Cuánto sobresale el sello por arriba y por la derecha de la tarjeta.
  ///
  /// Se eligió mirando el resultado a 390 px: el sello tiene que quedar sobre
  /// el papel, no encima de la línea de tinta del borde, o el número se pierde.
  final Offset badgeInset;

  static const Offset defaultBadgeInset = Offset(3, 17);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltDegrees * 0.0174532925,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _card(),
          if (badge != null)
            Positioned(
              top: -badgeInset.dy,
              right: -badgeInset.dx,
              child: badge!,
            ),
        ],
      ),
    );
  }

  Widget _card() {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
        ],
      ),
      child: Material(
        color: tokens.panel,
        shape: Border.all(color: tokens.ink, width: tokens.borderWidth),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: tokens.chipSelected,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      kicker,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: tokens.chipSelectedText,
                      ),
                    ),
                    Text(
                      number,
                      style: AppFonts.displayStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: tokens.chipSelectedText,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _MiniPanel(
                      tokens: tokens,
                      product: mine,
                      caption: 'TÚ ENTREGAS',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: tokens.halftone,
                      ),
                    ),
                    _MiniPanel(
                      tokens: tokens,
                      product: theirs,
                      caption: 'TÚ RECIBES',
                      highlighted: true,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            theirs.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.displayStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: tokens.text,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: tokens.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.halftone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.tokens,
    required this.product,
    required this.caption,
    this.highlighted = false,
  });

  final InkTokens tokens;
  final Product? product;
  final String caption;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 54,
          decoration: BoxDecoration(
            color: tokens.avatarWash,
            border: Border.all(
              color: highlighted ? tokens.chipSelectedBorder : tokens.ink,
              width: 2,
            ),
          ),
          child: product == null
              ? Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: tokens.muted,
                  ),
                )
              : product!.images.isEmpty
                  ? Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover)
                  : FadeInImage(
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      image: NetworkImage(product!.images.first),
                      placeholder:
                          const AssetImage('assets/images/no-image.jpg'),
                    ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: tokens.muted,
          ),
        ),
      ],
    );
  }
}
