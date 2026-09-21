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

import '../widgets/ink_exchange_card.dart';
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

class _View extends ConsumerStatefulWidget {
  const _View({
    required this.inbox,
    required this.tokens,
    required this.onOpenMenu,
  });

  final ExchangeInbox inbox;
  final InkTokens tokens;
  final VoidCallback onOpenMenu;

  @override
  ConsumerState<_View> createState() => _ViewState();
}

class _ViewState extends ConsumerState<_View> with ExchangeListRefresh {
  ExchangeInbox get inbox => widget.inbox;
  InkTokens get tokens => widget.tokens;

  bool get _isReceived => inbox == ExchangeInbox.received;

  @override
  Widget build(BuildContext context) {
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
          onOpenMenu: widget.onOpenMenu,
        ),
        Expanded(
          child: ExchangeRefreshIndicator(
            tokens: tokens,
            onRefresh: refreshExchanges,
            child: status != null
                ? ScrollableStatus(child: status)
                : ListView.separated(
                    physics: ExchangeRefreshIndicator.physics,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) => InkExchangeCard(
                      tokens: tokens,
                      kicker: _isReceived ? 'TE PROPONEN' : 'PROPUESTA ENVIADA',
                      number: (index + 1).toString().padLeft(2, '0'),
                      theirs: rows[index].theirs,
                      mine: rows[index].mine,
                      actionLabel: 'Ver propuesta',
                      tiltDegrees: index.isEven ? -0.6 : 0.5,
                      onTap: () => pushAndRefresh(context.push(
                        _isReceived
                            ? AppRoutes.previewReceived(rows[index].exchange.id)
                            : AppRoutes.previewRequested(
                                rows[index].exchange.id),
                      )),
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
