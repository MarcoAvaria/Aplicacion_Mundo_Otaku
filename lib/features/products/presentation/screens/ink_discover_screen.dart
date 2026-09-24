import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../delegates/product_search_delegate.dart';

/// Pantalla principal en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `DiscoverScreen` (paginación, búsqueda y
/// exclusión de los productos propios) y cambia solo la presentación.
class InkDiscoverScreen extends StatefulWidget {
  static const String name = 'ink_discover_screen';

  const InkDiscoverScreen({super.key});

  @override
  State<InkDiscoverScreen> createState() => _InkDiscoverScreenState();
}

class _InkDiscoverScreenState extends State<InkDiscoverScreen> {
  /// La llave vive en el estado y no en `build`. Si se creara en cada
  /// reconstrucción, Flutter no podría emparejar el elemento y destruiría el
  /// `Scaffold`: se cerraría el menú y se perdería cualquier `SnackBar` u hoja
  /// inferior abierta.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final tokens = InkTokens.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: tokens.paper,
      drawer: StyledNavigationDrawer(scaffoldKey: _scaffoldKey),
      body: SafeArea(
        bottom: false,
        child: _DiscoverView(scaffoldKey: _scaffoldKey, tokens: tokens),
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

class _DiscoverView extends ConsumerStatefulWidget {
  const _DiscoverView({required this.scaffoldKey, required this.tokens});

  final GlobalKey<ScaffoldState> scaffoldKey;
  final InkTokens tokens;

  @override
  ConsumerState<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState<_DiscoverView> {
  static const _types = ['Todo', 'Manga', 'Ropa', 'Taza', 'Otros'];

  final ScrollController scrollController = ScrollController();
  String _selectedType = _types.first;

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

  Future<void> _openSearch() async {
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final product = await showSearch<Product?>(
      context: context,
      delegate: ProductSearchDelegate(
        repository: ref.read(productsRepositoryProvider),
        currentUserId: currentUserId,
      ),
    );
    if (product == null || !mounted) return;
    context.push(AppRoutes.otherProduct(product.id));
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);

    final fullName = authState.user?.fullName.trim() ?? '';
    final initial =
        fullName.isEmpty ? 'O' : fullName.substring(0, 1).toUpperCase();

    final fromOthers = productsState.products
        .where((product) => authState.user?.id != product.user?.id)
        .toList();
    final products = _selectedType == _types.first
        ? fromOthers
        : fromOthers
            .where((product) =>
                product.typeOf.toLowerCase() == _selectedType.toLowerCase())
            .toList();

    // El filtro se aplica sobre las páginas ya cargadas: si todavía no hay
    // coincidencias y quedan páginas, se pide la siguiente.
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
          initial: initial,
          onOpenMenu: () => widget.scaffoldKey.currentState?.openDrawer(),
          onOpenSearch: _openSearch,
          types: _types,
          selectedType: _selectedType,
          onTypeSelected: (type) => setState(() => _selectedType = type),
        ),
        Expanded(
          child: _Results(
            tokens: tokens,
            products: products,
            state: productsState,
            isLoadingMore: shouldLoadMore,
            controller: scrollController,
            selectedType: _selectedType,
          ),
        ),
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.tokens,
    required this.products,
    required this.state,
    required this.isLoadingMore,
    required this.controller,
    required this.selectedType,
  });

  final InkTokens tokens;
  final List<Product> products;
  final ProductsState state;
  final bool isLoadingMore;
  final ScrollController controller;
  final String selectedType;

  /// Inclinaciones alternadas para que ninguna columna quede perfectamente recta.
  static const _tilts = [-1.1, 1.2, 0.6, -0.7];
  static const _heights = [126.0, 158.0, 92.0, 110.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if ((state.isLoading || isLoadingMore) && products.isEmpty) {
      return const ListStatusView(
        message: 'Cargando productos...',
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
      return ListStatusView(
        message: selectedType == 'Todo'
            ? 'Aún no hay publicaciones de otros usuarios.'
            : 'Nadie ha publicado algo en $selectedType todavía.\n'
                'Toca «Todo» para volver a ver el resto.',
      );
    }

    return MasonryGridView.count(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 96),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 13,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => context.push(AppRoutes.otherProduct(product.id)),
          child: InkDiscoverCard(
            product: product,
            tiltDegrees: _tilts[index % _tilts.length],
            imageHeight: _heights[index % _heights.length],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tokens,
    required this.initial,
    required this.onOpenMenu,
    required this.onOpenSearch,
    required this.types,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final InkTokens tokens;
  final String initial;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenSearch;
  final List<String> types;
  final String selectedType;
  final ValueChanged<String> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkMenuButton(tokens: tokens, onPressed: onOpenMenu),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tokens.avatarWash,
                  border: Border.all(color: tokens.ink, width: 2.5),
                ),
                child: CustomPaint(
                  painter: HalftonePainter(color: tokens.halftone),
                  child: Center(
                    child: Text(
                      initial,
                      style: AppFonts.displayStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tokens.halftone,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // El título se anuncia como un solo encabezado. Partido en dos
                // `Text` por el salto de línea del diseño, un lector de
                // pantalla leería dos fragmentos sueltos y la pantalla quedaría
                // sin ningún elemento con rol de título.
                child: Semantics(
                  header: true,
                  label: 'Cambia y descubre',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cambia',
                        style: AppFonts.displayStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                          letterSpacing: -0.8,
                          color: tokens.text,
                        ),
                      ),
                      Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Positioned(
                            left: 0,
                            right: -6,
                            bottom: 5,
                            child: Transform.rotate(
                              angle: -0.017,
                              child: Container(
                                height: 9,
                                color: tokens.accent.withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                          Text(
                            'y descubre',
                            style: AppFonts.displayStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 0.95,
                              letterSpacing: -0.8,
                              color: tokens.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 10),
                child: VerticalCjkLabel(color: tokens.halftone),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: InkWell(
            onTap: onOpenSearch,
            child: Container(
              padding: const EdgeInsets.only(bottom: 7),
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: tokens.ink, width: 2.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: tokens.ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Busca un tomo, una figura, un manhwa…',
                      style: TextStyle(fontSize: 14.5, color: tokens.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final type = types[index];
              return _TypeChip(
                tokens: tokens,
                label: type,
                selected: type == selectedType,
                onTap: () => onTypeSelected(type),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final InkTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.chipSelected : tokens.panel,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? tokens.chipSelectedBorder : tokens.ink,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? tokens.chipSelectedText : tokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
