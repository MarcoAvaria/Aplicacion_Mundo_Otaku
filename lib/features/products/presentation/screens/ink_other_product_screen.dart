import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_image_scroll_behavior.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ficha del producto de otra persona, en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `OtherProductScreen`: la propuesta se arma
/// eligiendo uno de tus productos y confirmando antes de enviarla.
class InkOtherProductScreen extends ConsumerWidget {
  static const String name = 'ink_other_product_screen';

  final String productId;

  const InkOtherProductScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = InkTokens.of(context);
    final productState = ref.watch(productProvider(productId));
    final productsState = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);

    final myProducts = productsState.products
        .where((product) => authState.user?.id == product.user?.id)
        .toList();

    return Scaffold(
      backgroundColor: tokens.paper,
      body: productState.isLoading
          ? const FullScreenLoader()
          : productState.errorMessage.isNotEmpty && productState.product == null
              ? ListStatusView(
                  message: productState.errorMessage,
                  onRetry: () =>
                      ref.read(productProvider(productId).notifier).loadProduct(),
                )
              : productState.product == null
                  ? const ListStatusView(
                      message: 'El producto ya no está disponible.',
                    )
                  : _View(
                      tokens: tokens,
                      product: productState.product!,
                      myProducts: myProducts,
                    ),
    );
  }
}

class _View extends ConsumerWidget {
  const _View({
    required this.tokens,
    required this.product,
    required this.myProducts,
  });

  final InkTokens tokens;
  final Product product;
  final List<Product> myProducts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = product.user?.fullName.trim();

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _Cover(tokens: tokens, product: product),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: AppFonts.displayStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.6,
                        color: tokens.text,
                      ),
                    ),
                    if (owner != null && owner.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _OwnerCard(tokens: tokens, name: owner),
                    ],
                    const SizedBox(height: 20),
                    _Facts(tokens: tokens, product: product),
                    if (product.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'DESCRIPCIÓN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: tokens.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: tokens.text,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ProposeBar(
          tokens: tokens,
          product: product,
          myProducts: myProducts,
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.tokens, required this.product});

  final InkTokens tokens;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final type = product.typeOf.trim();

    return SizedBox(
      height: 330,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: tokens.avatarWash,
              child: CustomPaint(
                painter: HalftonePainter(
                  color: tokens.halftone,
                  spacing: 9,
                  opacity: 0.22,
                ),
                child: product.images.isEmpty
                    ? Image.asset('assets/images/no-image.jpg',
                        fit: BoxFit.cover)
                    // Conserva el arreglo del arrastre con ratón en web (R-24).
                    : PageView(
                        scrollBehavior: const ProductImageScrollBehavior(),
                        children: [
                          for (var index = 0;
                              index < product.images.length;
                              index++)
                            FadeInImage(
                              imageSemanticLabel:
                                  'Foto ${index + 1} de ${product.images.length}',
                              fit: BoxFit.cover,
                              image:
                                  imageProviderForPath(product.images[index]),
                              placeholder: const AssetImage(
                                'assets/images/no-image.jpg',
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: tokens.borderWidth, color: tokens.ink),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  children: [
                    _RoundButton(
                      tokens: tokens,
                      icon: Icons.arrow_back,
                      label: 'Volver',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    VerticalCjkLabel(color: tokens.halftone),
                  ],
                ),
              ),
            ),
          ),
          if (type.isNotEmpty)
            Positioned(
              left: 18,
              bottom: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.chipSelected,
                  border: Border.all(color: tokens.ink, width: 2),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: tokens.chipSelectedText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final InkTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: tokens.panel,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: tokens.ink, width: 2.5),
            ),
            child: Icon(icon, size: 20, color: tokens.text),
          ),
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.tokens, required this.name});

  final InkTokens tokens;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border.all(color: tokens.ink, width: tokens.borderWidth),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.avatarWash,
              border: Border.all(color: tokens.ink, width: 2),
            ),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: tokens.halftone,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUBLICADO POR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.displayStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.tokens, required this.product});

  final InkTokens tokens;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      if (product.tomo > 0) 'Tomo ${product.tomo}',
      for (final value in [product.demographic, product.gender])
        if (value.trim().isNotEmpty && value.trim().toLowerCase() != 'ninguno')
          productOptionLabel(value.trim()),
      if (product.sizeOf.trim().isNotEmpty &&
          product.sizeOf.trim().toLowerCase() != 'ninguno')
        'Talla ${product.sizeOf.trim()}',
      ...product.tags.where((tag) => tag.trim().isNotEmpty),
    ];

    if (facts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final fact in facts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.panel,
              border: Border.all(color: tokens.ink, width: 2),
            ),
            child: Text(
              fact,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: tokens.text,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProposeBar extends ConsumerWidget {
  const _ProposeBar({
    required this.tokens,
    required this.product,
    required this.myProducts,
  });

  final InkTokens tokens;
  final Product product;
  final List<Product> myProducts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(top: BorderSide(color: tokens.ink, width: 2)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          child: InkHardButton(
            tokens: tokens,
            icon: Icons.swap_horiz_rounded,
            label: 'Proponer intercambio',
            onTap: () => _openMyProducts(context, ref),
          ),
        ),
      ),
    );
  }

  void _openMyProducts(BuildContext context, WidgetRef ref) {
    if (myProducts.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero publica algo tuyo para poder proponer un cambio.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.paper,
      shape: const RoundedRectangleBorder(),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Qué ofreces a cambio?',
                      style: AppFonts.displayStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige uno de tus productos',
                      style: TextStyle(fontSize: 13, color: tokens.muted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  itemCount: myProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final mine = myProducts[index];
                    return InkProductRow(
                      product: mine,
                      tiltDegrees: index.isEven ? -0.4 : 0.4,
                      onTap: () => _confirm(sheetContext, context, ref, mine),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirm(
    BuildContext sheetContext,
    BuildContext screenContext,
    WidgetRef ref,
    Product mine,
  ) {
    showDialog<void>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar la propuesta'),
        content: Text(
          'Ofreces «${mine.title}» a cambio de «${product.title}».\n\n'
          '¿Enviamos la solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Todavía no'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final wasCreated = await ref
                  .read(chatExchangesProvider.notifier)
                  .createChatExchange({
                'product1': product.id,
                'product2': mine.id,
                'requester1': mine.id,
              });
              if (!sheetContext.mounted || !screenContext.mounted) return;

              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(screenContext).clearSnackBars();
              ScaffoldMessenger.of(screenContext).showSnackBar(
                SnackBar(
                  content: Text(
                    wasCreated
                        ? 'Propuesta enviada. Te avisaremos cuando respondan.'
                        : 'No fue posible enviar la propuesta. Inténtalo otra vez.',
                  ),
                ),
              );
            },
            child: const Text('Sí, enviar'),
          ),
        ],
      ),
    );
  }
}
