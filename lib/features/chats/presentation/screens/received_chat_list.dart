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

class ReceivedListScreen extends StatelessWidget {
  static const String name = 'received_list_screen';

  const ReceivedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: ConfigurationMenu(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(context, '¡Solicitudes recibidas!'),
      body: const _ReceivedListView(),
    );
  }
}

class _ReceivedListView extends ConsumerWidget {
  const _ReceivedListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangesState = ref.watch(chatExchangesProvider);
    final productsState = ref.watch(productsProvider);
    final userId = ref.watch(authProvider).user?.id ?? '';
    final productsById = {
      for (final product in productsState.products) product.id: product,
    };
    final rows = <_ExchangeRow>[];
    var hasUnresolvedProduct = false;

    for (final exchange in exchangesState.chatExchanges) {
      if (exchange.status != 'pending' || exchange.owner1 != userId) continue;
      final product = productsById[exchange.product2];
      if (product == null) {
        hasUnresolvedProduct = true;
      } else {
        rows.add(_ExchangeRow(product, exchange));
      }
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
      emptyMessage: 'No tienes solicitudes recibidas pendientes.',
    );
    if (status != null) return status;

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return ListTile(
          leading: ProductListAvatar(product: row.product),
          title: Text(row.product.title),
          onTap: () => context.push(AppRoutes.previewReceived(row.exchange.id)),
        );
      },
    );
  }
}

class _ExchangeRow {
  final Product product;
  final ChatExchange exchange;

  const _ExchangeRow(this.product, this.exchange);
}
