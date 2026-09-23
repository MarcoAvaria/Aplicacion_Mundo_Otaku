import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Mi estante" en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `ProductsScreen`: pagina sobre el mismo
/// proveedor y muestra solo los productos propios.
class InkProductsScreen extends ConsumerWidget {
  static const String name = 'ink_products_screen';

  const InkProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final tokens = InkTokens.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: tokens.paper,
      drawer: StyledNavigationDrawer(scaffoldKey: scaffoldKey),
      body: SafeArea(
        bottom: false,
        child: _ProductsView(scaffoldKey: scaffoldKey, tokens: tokens),
      ),
      floatingActionButton: InkHardButton(
        tokens: tokens,
        icon: Icons.add_rounded,
        label: 'Publicar',
        onTap: () => context.push(AppRoutes.product('new')),
      ),
    );
  }
}

class _ProductsView extends ConsumerStatefulWidget {
  const _ProductsView({required this.scaffoldKey, required this.tokens});

  final GlobalKey<ScaffoldState> scaffoldKey;
  final InkTokens tokens;

  @override
  ConsumerState<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<_ProductsView> {
  final ScrollController scrollController = ScrollController();

  InkTokens get tokens => widget.tokens;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if ((scrollController.position.pixels + 400) >=
          scrollController.position.maxScrollExtent) {
        ref.read(productsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);
    final products = productsState.products
        .where((product) => authState.user?.id == product.user?.id)
        .toList();

    final shouldLoadMore = products.isEmpty &&
        !productsState.isLoading &&
        !productsState.isLastPage &&
        productsState.errorMessage.isEmpty;
    if (shouldLoadMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productsProvider.notifier).loadNextPage();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          tokens: tokens,
          count: products.length,
          onOpenMenu: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
        if (products.isNotEmpty) _SpineStrip(tokens: tokens, products: products),
        Expanded(
          child: _Body(
            tokens: tokens,
            products: products,
            state: productsState,
            isLoadingMore: shouldLoadMore,
            controller: scrollController,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tokens,
    required this.count,
    required this.onOpenMenu,
  });

  final InkTokens tokens;
  final int count;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkMenuButton(tokens: tokens, onPressed: onOpenMenu),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi estante',
                      style: AppFonts.displayStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                        letterSpacing: -0.8,
                        color: tokens.text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      count == 1
                          ? '1 producto publicado'
                          : '$count productos publicados',
                      style: TextStyle(fontSize: 13.5, color: tokens.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 10),
                child: VerticalCjkLabel(color: tokens.halftone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tira de lomos: los primeros productos puestos de canto, como en un estante.
class _SpineStrip extends StatelessWidget {
  const _SpineStrip({required this.tokens, required this.products});

  final InkTokens tokens;
  final List<Product> products;

  static const _widths = [38.0, 32.0, 42.0, 30.0, 36.0];
  static const _heights = [112.0, 104.0, 118.0, 96.0, 108.0];

  @override
  Widget build(BuildContext context) {
    final shown = products.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TUS ÚLTIMOS TOMOS',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              // `halftone`, no `accent`: en modo oscuro `accent` es un ciruela
              // muy oscuro pensado para rellenar superficies, y sobre el papel
              // casi negro este rótulo quedaba ilegible. El magenta que se lee
              // vive en `halftone`, que es lo que usan las otras seis pantallas.
              color: tokens.halftone,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < shown.length; index++) ...[
                  _Spine(
                    tokens: tokens,
                    title: shown[index].title,
                    width: _widths[index % _widths.length],
                    height: _heights[index % _heights.length],
                    filled: index == 0,
                  ),
                  const SizedBox(width: 6),
                ],
                if (products.length > shown.length)
                  Expanded(
                    child: Container(
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.panel,
                        border: Border.all(
                          color: tokens.ink,
                          width: tokens.borderWidth,
                        ),
                      ),
                      child: CustomPaint(
                        painter: HalftonePainter(color: tokens.halftone),
                        child: Center(
                          child: Container(
                            color: tokens.paper,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              '+${products.length - shown.length} más',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.text,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _Spine extends StatelessWidget {
  const _Spine({
    required this.tokens,
    required this.title,
    required this.width,
    required this.height,
    required this.filled,
  });

  final InkTokens tokens;
  final String title;
  final double width;
  final double height;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? tokens.accent : tokens.panel,
        border: Border.all(color: tokens.ink, width: tokens.borderWidth),
      ),
      // En un lomo real el texto va acostado, así que rotarlo es lo correcto.
      child: RotatedBox(
        quarterTurns: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.displayStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? tokens.onAccent : tokens.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.tokens,
    required this.products,
    required this.state,
    required this.isLoadingMore,
    required this.controller,
  });

  final InkTokens tokens;
  final List<Product> products;
  final ProductsState state;
  final bool isLoadingMore;
  final ScrollController controller;

  static const _tilts = [-0.5, 0.4, -0.3, 0.6];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((state.isLoading || isLoadingMore) && products.isEmpty) {
      return const ListStatusView(
        message: 'Cargando tus productos...',
        isLoading: true,
      );
    }

    if (state.errorMessage.isNotEmpty && products.isEmpty) {
      return ListStatusView(
        message: state.errorMessage,
        onRetry: () => ref.read(productsProvider.notifier).loadNextPage(),
      );
    }

    if (products.isEmpty) {
      return const ListStatusView(
        message: 'Tu estante está vacío.\n'
            'Publica algo que ya no estés leyendo y empieza a cambiar.',
      );
    }

    return ListView.separated(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 96),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 13),
      itemBuilder: (context, index) {
        final product = products[index];
        return InkProductRow(
          product: product,
          tiltDegrees: _tilts[index % _tilts.length],
          onTap: () => context.push(AppRoutes.product(product.id)),
        );
      },
    );
  }
}
