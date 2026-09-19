import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exchange_list_support.dart';

/// Cuál de las dos bandejas se está mostrando.
///
/// Las dos listas recorren los mismos intercambios pendientes y solo cambian
/// de lado: quién es la persona dueña y cuál producto es el propio.
enum ExchangeInbox { received, sent }

/// Bandeja de solicitudes en la dirección "Tinta y Neón".
///
/// Cada fila es una doble página: lo que entregas y lo que recibes.
class InkExchangeListScreen extends ConsumerWidget {
  const InkExchangeListScreen({super.key, required this.inbox});

  final ExchangeInbox inbox;

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
        child: _View(
          inbox: inbox,
          tokens: tokens,
          onOpenMenu: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }
}

class _View extends ConsumerWidget {
  const _View({
    required this.inbox,
    required this.tokens,
    required this.onOpenMenu,
  });

  final ExchangeInbox inbox;
  final InkTokens tokens;
  final VoidCallback onOpenMenu;

  bool get _isReceived => inbox == ExchangeInbox.received;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangesState = ref.watch(chatExchangesProvider);
    final productsState = ref.watch(productsProvider);
    final userId = ref.watch(authProvider).user?.id ?? '';
    final productsById = {
      for (final product in productsState.products) product.id: product,
    };

    final rows = <_Row>[];
    var hasUnresolvedProduct = false;

    for (final exchange in exchangesState.chatExchanges) {
      if (exchange.status != 'pending') continue;
      final owner = _isReceived ? exchange.owner1 : exchange.owner2;
      if (owner != userId) continue;

      // product1 es lo solicitado y product2 lo ofrecido a cambio.
      final theirsId = _isReceived ? exchange.product2 : exchange.product1;
      final minesId = _isReceived ? exchange.product1 : exchange.product2;
      final theirs = productsById[theirsId];
      if (theirs == null) {
        hasUnresolvedProduct = true;
        continue;
      }
      rows.add(_Row(exchange, theirs, productsById[minesId]));
    }

    final waitingForProducts = hasUnresolvedProduct &&
        !productsState.isLastPage &&
        productsState.errorMessage.isEmpty;
    if (waitingForProducts && !productsState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productsProvider.notifier).loadNextPage();
      });
    }

    final status = buildExchangeListStatus(
      ref: ref,
      userId: userId,
      exchangesState: exchangesState,
      productsState: productsState,
      isEmpty: rows.isEmpty,
      waitingForProducts: waitingForProducts,
      emptyMessage: _isReceived
          ? 'No tienes solicitudes recibidas pendientes.'
          : 'No tienes solicitudes enviadas pendientes.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          tokens: tokens,
          title: _isReceived ? 'Recibidas' : 'Enviadas',
          subtitle: _subtitle(rows.length),
          onOpenMenu: onOpenMenu,
        ),
        Expanded(
          child: status ??
              ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) => _ExchangeCard(
                  tokens: tokens,
                  row: rows[index],
                  isReceived: _isReceived,
                  tiltDegrees: index.isEven ? -0.6 : 0.5,
                  index: index,
                  onOpen: () => context.push(
                    _isReceived
                        ? AppRoutes.previewReceived(rows[index].exchange.id)
                        : AppRoutes.previewRequested(rows[index].exchange.id),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  String _subtitle(int count) {
    if (count == 0) {
      return _isReceived
          ? 'Nadie te ha propuesto un cambio por ahora'
          : 'Todavía no has propuesto ningún cambio';
    }
    if (count == 1) {
      return _isReceived
          ? 'Una persona quiere algo de tu estante'
          : 'Una propuesta esperando respuesta';
    }
    return _isReceived
        ? '$count personas quieren algo de tu estante'
        : '$count propuestas esperando respuesta';
  }
}

class _Row {
  const _Row(this.exchange, this.theirs, this.mine);

  final ChatExchange exchange;

  /// El producto de la otra persona.
  final Product theirs;

  /// El propio, cuando alcanzó a cargarse.
  final Product? mine;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.onOpenMenu,
  });

  final InkTokens tokens;
  final String title;
  final String subtitle;
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
                      title,
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
                      subtitle,
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

/// Una solicitud, contada como una doble página: lo que entregas y lo que
/// recibes, con la flecha de intercambio entre medio.
class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.tokens,
    required this.row,
    required this.isReceived,
    required this.tiltDegrees,
    required this.index,
    required this.onOpen,
  });

  final InkTokens tokens;
  final _Row row;
  final bool isReceived;
  final double tiltDegrees;
  final int index;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
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
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: tokens.chipSelected,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isReceived ? 'TE PROPONEN' : 'PROPUESTA ENVIADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: tokens.chipSelectedText,
                        ),
                      ),
                      Text(
                        (index + 1).toString().padLeft(2, '0'),
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
                        product: row.mine,
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
                        product: row.theirs,
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
                              row.theirs.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.displayStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                color: tokens.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ver propuesta',
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
