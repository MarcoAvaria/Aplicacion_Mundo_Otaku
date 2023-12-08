import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';

class ChatListScreen extends StatelessWidget {
  static const String name = 'chat_list_screen';
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: ConfigurationMenu( scaffoldKey: scaffoldKey ),
      appBar: CustomAppBar.customAppBar(context, '¡Chats!'),
      body: const _ChatListView(),
    );
  }
}

class _ChatListView extends ConsumerStatefulWidget {
  const _ChatListView();
  @override
  _ChatListState createState() => _ChatListState();
}


class _ChatListState extends ConsumerState {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState(); 
  }
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final chatExchangesState = ref.watch( chatExchangesProvider );
    List<ChatExchange> listaTotalChat = chatExchangesState.chatExchanges;
    final productsState = ref.watch( productsProvider );
    final authState = ref.watch(authProvider);
    List<Product> listaDeProductos = productsState.products.where(
      (product) => product.user?.id != authState.user?.id).toList(); 
    
    List<Product> filteredProducts = listaDeProductos
      .where((product1) =>
          listaTotalChat.any((chatExchange) =>
              (product1.id == chatExchange.product1) ||
              (product1.id == chatExchange.product2)))
      .toList();

    return ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return ListTile(
            
            //leading: CircleAvatar(backgroundImage: NetworkImage(user.profileImage)),
            title: Text(product.title),
            onTap: () {
              
            },
        
          );
        },
      );
  }
}