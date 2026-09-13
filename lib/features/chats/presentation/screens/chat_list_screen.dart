import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'exchange_list_support.dart';

class ChatListScreen extends StatelessWidget {
  static const String name = 'chat_list_screen';

  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: ConfigurationMenu(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(context, '¡Chats!'),
      body: const _ChatListView(),
    );
  }
}

class _ChatListView extends ConsumerWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangesState = ref.watch(chatExchangesProvider);
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
      final otherProduct = productsById[otherProductId];
      if (otherProduct == null) {
        hasUnresolvedProduct = true;
        continue;
      }

      rows.add(_ChatRow(
        product: otherProduct,
        exchange: exchange,
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
      emptyMessage:
          'No tienes intercambios aceptados. Cuando aceptes una propuesta, el chat aparecerá aquí.',
    );
    if (status != null) return status;

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          leading: ProductListAvatar(product: row.product),
          title: Text(row.product.title),
          onTap: () => context.push(AppRoutes.chat(
            conversationId: row.exchange.id,
            myProductId: row.myProductId,
            otherProductId: row.otherProductId,
          )),
        );
      },
    );
  }
}

class _ChatRow {
  final Product product;
  final ChatExchange exchange;
  final String myProductId;
  final String otherProductId;

  const _ChatRow({
    required this.product,
    required this.exchange,
    required this.myProductId,
    required this.otherProductId,
  });
}
