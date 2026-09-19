import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

import '../delegates/product_search_delegate.dart';

class DiscoverScreen extends ConsumerWidget {
  static const String name = 'discover_screen';

  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final currentUserId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      drawer: StyledNavigationDrawer(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(
        context,
        '¡Cambia y descubre!',
        onSearch: () async {
          final product = await showSearch<Product?>(
            context: context,
            delegate: ProductSearchDelegate(
              repository: ref.read(productsRepositoryProvider),
              currentUserId: currentUserId,
            ),
          );
          if (product == null || !context.mounted) return;
          context.push(AppRoutes.otherProduct(product.id));
        },
      ),
      body: const _DiscoverView(),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Nuevo producto'),
        icon: const Icon(Icons.add),
        onPressed: () {
          context.push(AppRoutes.product('new'));
        },
      ),
    );
  }
}

class _DiscoverView extends ConsumerStatefulWidget {
  const _DiscoverView();

  @override
  _DiscoverViewState createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState {
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
    final authState = ref.watch(authProvider);
    final products = productsState.products
        .where((product) => authState.user?.id != product.user?.id)
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
        message: 'Cargando productos...',
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
        message: 'Aún no hay publicaciones de otros usuarios.',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: MasonryGridView.count(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        crossAxisCount: 1,
        mainAxisSpacing: 20,
        crossAxisSpacing: 35,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => context.push(AppRoutes.otherProduct(product.id)),
            child: DiscoverCard(product: product),
          );
        },
      ),
    );
  }
}
