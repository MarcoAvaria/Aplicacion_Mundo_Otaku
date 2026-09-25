import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_option_labels.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';

/// Tarjeta de producto como viñeta de manga: borde de tinta, sombra dura sin
/// desenfoque y una inclinación leve que rompe la cuadrícula.
class InkDiscoverCard extends StatelessWidget {
  const InkDiscoverCard({
    super.key,
    required this.product,
    required this.tiltDegrees,
    required this.imageHeight,
  });

  final Product product;
  final double tiltDegrees;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = _CardTokens.of(context);
    final flag = _flagLabel(product);
    final subtitle = _subtitleFor(product);

    return Transform.rotate(
      angle: tiltDegrees * 0.0174532925,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.panel,
          border: Border.all(color: tokens.border, width: tokens.borderWidth),
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: tokens.imageBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: tokens.border,
                        width: tokens.borderWidth,
                      ),
                    ),
                  ),
                  child: _Cover(images: product.images, height: imageHeight),
                ),
                if (flag != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      color: tokens.border,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      child: Text(
                        flag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: tokens.flagForeground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.displayStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: tokens.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _flagLabel(Product product) {
    if (product.muestraTomo) return 'TOMO ${product.tomo}';
    final type = product.typeOf.trim();
    return type.isEmpty ? null : type.toUpperCase();
  }

  static String? _subtitleFor(Product product) {
    final parts = <String>[];
    for (final value in [product.demographic, product.gender]) {
      final clean = value.trim();
      if (clean.isEmpty || clean.toLowerCase() == 'ninguno') continue;
      parts.add(productOptionLabel(clean));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.images, required this.height});

  final List<String> images;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Image.asset(
        'assets/images/no-image.jpg',
        fit: BoxFit.cover,
        height: height,
      );
    }
    return FadeInImage(
      fit: BoxFit.cover,
      height: height,
      fadeOutDuration: const Duration(milliseconds: 100),
      fadeInDuration: const Duration(milliseconds: 200),
      image: NetworkImage(images.first),
      placeholder: const AssetImage('assets/images/no-image.jpg'),
    );
  }
}

class _CardTokens {
  const _CardTokens({
    required this.panel,
    required this.border,
    required this.borderWidth,
    required this.text,
    required this.muted,
    required this.shadow,
    required this.imageBackground,
    required this.flagForeground,
  });

  final Color panel;
  final Color border;
  final double borderWidth;
  final Color text;
  final Color muted;
  final Color shadow;
  final Color imageBackground;
  final Color flagForeground;

  factory _CardTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const _CardTokens(
        panel: Color(0xFF1B1820),
        border: Color(0xFF2C2833),
        borderWidth: 1.8,
        text: Color(0xFFF1EEF5),
        muted: Color(0xFF9089A0),
        shadow: Color(0xFF000000),
        imageBackground: Color(0xFF221C29),
        flagForeground: Color(0xFFF1EEF5),
      );
    }

    return const _CardTokens(
      panel: Color(0xFFFFFFFF),
      border: Color(0xFF241626),
      borderWidth: 2.5,
      text: Color(0xFF241626),
      muted: Color(0xFF6E5F6C),
      shadow: Color(0xFF241626),
      imageBackground: Color(0xFFF6EAF2),
      flagForeground: Color(0xFFFDF9FC),
    );
  }
}
