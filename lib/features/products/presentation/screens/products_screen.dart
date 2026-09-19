import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_grid_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

import '../../../auth/auth.dart';

class ProductsScreen extends StatelessWidget {
  static const String name = 'products_screen';

  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      drawer: StyledNavigationDrawer(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(context, 'Mis productos'),
      body: const _ProductsView(),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Nuevo producto'),
        icon: const Icon(Icons.add_rounded),
        onPressed: () {
          context.push(AppRoutes.product('new'));
        },
      ),
    );
  }
}

class _ProductsView extends ConsumerStatefulWidget {
  const _ProductsView();

  @override
  _ProductsViewState createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState {
  final ScrollController scrollController = ScrollController();

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

    //final container = ProviderContainer();
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

    if ((productsState.isLoading || shouldLoadMore) && products.isEmpty) {
      return const ListStatusView(
        message: 'Cargando tus productos...',
        isLoading: true,
      );
    }

    if (productsState.errorMessage.isNotEmpty && products.isEmpty) {
      return ListStatusView(
        message: productsState.errorMessage,
        onRetry: () => ref.read(productsProvider.notifier).loadNextPage(),
      );
    }

    if (products.isEmpty) {
      return const ListStatusView(
        message: 'Todavía no has publicado productos.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth.clamp(0.0, 760.0);
        const horizontalPadding = AppSpacing.lg;
        const gap = AppSpacing.lg;
        final cardWidth = (contentWidth - horizontalPadding * 2 - gap) / 2;
        final cardHeight = cardWidth * 4 / 3 + 96;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: GridView.builder(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                104,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: cardHeight,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductGridCard(
                  product: product,
                  onTap: () => context.push(AppRoutes.product(product.id)),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
