import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_option_labels.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/ink_tokens.dart';
import 'package:flutter/material.dart';

/// Fila de producto propio: viñeta horizontal con la portada al costado.
class InkProductRow extends StatelessWidget {
  const InkProductRow({
    super.key,
    required this.product,
    required this.tiltDegrees,
    required this.onTap,
  });

  final Product product;
  final double tiltDegrees;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);
    final details = _details(product);

    // La fila entera es tocable, así que se anuncia como botón. El nombre lo
    // aporta el texto que ya contiene (título y detalles), sin repetirlo aquí.
    return Semantics(
      button: true,
      child: Transform.rotate(
        angle: tiltDegrees * 0.0174532925,
        child: DecoratedBox(
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
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 78,
                      decoration: BoxDecoration(
                        color: tokens.avatarWash,
                        border: Border.all(
                          color: tokens.ink,
                          width: tokens.borderWidth,
                        ),
                      ),
                      child: product.images.isEmpty
                          ? Image.asset(
                              'assets/images/no-image.jpg',
                              fit: BoxFit.cover,
                            )
                          : FadeInImage(
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              image: NetworkImage(product.images.first),
                              placeholder: const AssetImage(
                                'assets/images/no-image.jpg',
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.displayStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: tokens.text,
                            ),
                          ),
                          if (details != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: tokens.ink, width: 2),
                            ),
                            child: Text(
                              product.typeOf.trim().isEmpty
                                  ? 'PRODUCTO'
                                  : product.typeOf.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: tokens.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _details(Product product) {
    final parts = <String>[];
    if (product.tomo > 0) parts.add('Tomo ${product.tomo}');
    for (final value in [product.demographic, product.gender]) {
      final clean = value.trim();
      if (clean.isEmpty || clean.toLowerCase() == 'ninguno') continue;
      parts.add(productOptionLabel(clean));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
