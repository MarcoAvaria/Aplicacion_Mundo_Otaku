import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildExchangeListStatus({
  required WidgetRef ref,
  required String userId,
  required ChatExchangesState exchangesState,
  required ProductsState productsState,
  required bool isEmpty,
  bool waitingForProducts = false,
  required String emptyMessage,
}) {
  if ((exchangesState.isLoading ||
          productsState.isLoading ||
          waitingForProducts) &&
      isEmpty) {
    return const ListStatusView(
      message: 'Cargando intercambios...',
      isLoading: true,
    );
  }

  final errorMessage = exchangesState.errorMessage.isNotEmpty
      ? exchangesState.errorMessage
      : productsState.errorMessage;
  if (errorMessage.isNotEmpty && isEmpty) {
    return ListStatusView(
      message: errorMessage,
      onRetry: () {
        if (exchangesState.errorMessage.isNotEmpty) {
          ref.read(chatExchangesProvider.notifier).loadAllChatExchanges(userId);
        }
        if (productsState.errorMessage.isNotEmpty) {
          ref.read(productsProvider.notifier).loadNextPage();
        }
      },
    );
  }

  if (isEmpty) return ListStatusView(message: emptyMessage);
  return null;
}

class ProductListAvatar extends StatelessWidget {
  final Product product;

  const ProductListAvatar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage:
          product.images.isEmpty ? null : NetworkImage(product.images.first),
      child: product.images.isEmpty
          ? const Icon(Icons.inventory_2_outlined)
          : null,
    );
  }
}
