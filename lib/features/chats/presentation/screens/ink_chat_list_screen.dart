import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_read_marks_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/widgets/ink_unread_badge.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/widgets/ink_exchange_card.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exchange_list_support.dart';

/// Los intercambios ya aceptados, que es donde vive cada conversación.
///
/// Conserva el comportamiento de `ChatListScreen`: solo los intercambios en
/// curso y la misma navegación al chat con los tres identificadores.
class InkChatListScreen extends StatefulWidget {
  static const String name = 'ink_chat_list_screen';

  const InkChatListScreen({super.key});

  @override
  State<InkChatListScreen> createState() => _InkChatListScreenState();
}

class _InkChatListScreenState extends State<InkChatListScreen> {
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
        child: _View(
          tokens: tokens,
          onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }
}

class _View extends ConsumerStatefulWidget {
  const _View({required this.tokens, required this.onOpenMenu});

  final InkTokens tokens;
  final VoidCallback onOpenMenu;

  @override
  ConsumerState<_View> createState() => _ViewState();
}

class _ViewState extends ConsumerState<_View> with ExchangeListRefresh {
  InkTokens get tokens => widget.tokens;

  @override
  Widget build(BuildContext context) {
    final exchangesState = ref.watch(chatExchangesProvider);
    final readMarks = ref.watch(chatReadMarksProvider.notifier);
    // Se observa el estado además del notifier para que el sello se redibuje
    // en cuanto se marca una conversación como leída.
    ref.watch(chatReadMarksProvider);
    final productsState = ref.watch(productsProvider);
    final userId = ref.watch(authProvider).user?.id ?? '';
    final productsById = {
      for (final product in productsState.products) product.id: product,
    };

    final rows = <_ChatRow>[];
    var hasUnresolvedProduct = false;

    for (final exchange in exchangesState.chatExchanges) {
      if (exchange.status != 'inProgress') continue;

      final isOwner1 = exchange.owner1 == userId;
      final isOwner2 = exchange.owner2 == userId;
      if (!isOwner1 && !isOwner2) continue;

      final myProductId = isOwner1 ? exchange.product1 : exchange.product2;
      final otherProductId = isOwner1 ? exchange.product2 : exchange.product1;
      // Se prefiere el producto que vino con el intercambio; el catálogo queda
      // solo como respaldo. Antes era al revés, y por eso una conversación no
      // aparecía hasta que el catálogo hubiera paginado hasta ese producto, ni
      // aparecía nunca si nadie visitaba Descubrir.
      final otherProduct = exchange.productoDeLaOtraPersona(userId) ??
          productsById[otherProductId];
      if (otherProduct == null) {
        hasUnresolvedProduct = true;
        continue;
      }

      rows.add(_ChatRow(
        exchange: exchange,
        theirs: otherProduct,
        mine: exchange.productoDe(userId) ?? productsById[myProductId],
        myProductId: myProductId,
        otherProductId: otherProductId,
      ));
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
      emptyMessage: 'Todavía no tienes intercambios aceptados.\n'
          'Cuando aceptes una propuesta, la conversación aparecerá aquí.',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          tokens: tokens,
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
                    // Más aire arriba y entre tarjetas que en las bandejas:
                    // el sello sobresale 17 px y no debe pisar la tarjeta de
                    // encima ni su sombra.
                    padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return InkExchangeCard(
                        tokens: tokens,
                        kicker: 'INTERCAMBIO EN CURSO',
                        number: (index + 1).toString().padLeft(2, '0'),
                        theirs: row.theirs,
                        mine: row.mine,
                        subtitle: row.theirs.user?.fullName.trim(),
                        actionLabel: 'Abrir la conversación',
                        tiltDegrees: index.isEven ? -0.6 : 0.5,
                        badge: InkUnreadBadge(
                          tokens: tokens,
                          count: readMarks.unreadCountFor(
                            exchange: row.exchange,
                            currentUserId: userId,
                          ),
                        ),
                        onTap: () => pushAndRefresh(context.push(AppRoutes.chat(
                          conversationId: row.exchange.id,
                          myProductId: row.myProductId,
                          otherProductId: row.otherProductId,
                        ))),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _subtitle(int count) {
    if (count == 0) return 'Aquí aparecen los cambios que ya acordaste';
    if (count == 1) return 'Un intercambio en curso';
    return '$count intercambios en curso';
  }
}

class _ChatRow {
  const _ChatRow({
    required this.exchange,
    required this.theirs,
    required this.mine,
    required this.myProductId,
    required this.otherProductId,
  });

  final ChatExchange exchange;
  final Product theirs;
  final Product? mine;
  final String myProductId;
  final String otherProductId;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tokens,
    required this.subtitle,
    required this.onOpenMenu,
  });

  final InkTokens tokens;
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
                      'Chats',
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
