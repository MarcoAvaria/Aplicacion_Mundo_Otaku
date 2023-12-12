import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class RequestedListScreen extends StatelessWidget {
  static const String name = 'requested_list_screen';
  const RequestedListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: ConfigurationMenu(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(context, 'Solicitudes enviadas'),
      body: const _RequestedListView(),
    );
  }
}

class _RequestedListView extends ConsumerStatefulWidget {
  const _RequestedListView();
  @override
  _RequestedListState createState() => _RequestedListState();
}

class _RequestedListState extends ConsumerState {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatExchangesProvider.notifier).loadAllChatExchanges();
    });

    scrollController.addListener(() {
      if ((scrollController.position.pixels + 200) >=
          scrollController.position.maxScrollExtent) {
        // También movemos esta llamada aquí para evitar problemas
        ref.read(chatExchangesProvider.notifier).loadNextPage();
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
    var chatExchangesState = ref.watch(chatExchangesProvider);
    List<ChatExchange> listaTotalChat = chatExchangesState.chatExchanges;
    var productsState = ref.watch(productsProvider);
    var authState = ref.watch(authProvider);
    List<Product> misProductos = productsState.products
        .where((product) => product.user?.id == authState.user?.id)
        .toList();

    //List<Product> listafinal = <Product>[];
    List<List<Object>> listafinal = [];

    for (ChatExchange conversacion in listaTotalChat) {
      for (Product miProducto in misProductos) {
        if ((miProducto.id == conversacion.requester1) &&
            (conversacion.status == 'pending')) {
          if (conversacion.product1 == miProducto.id) {
            listafinal.add([
              productsState.products
                  .firstWhere((product) => product.id == conversacion.product2),
              conversacion,
            ]);
          } else {
            listafinal.add([
              productsState.products
                  .firstWhere((product) => product.id == conversacion.product1),
              conversacion,
            ]);
          }
        }
      }
    }

    return ListView.builder(
      itemCount: listafinal.length,
      itemBuilder: (context, index) {
        final product = listafinal[index][0] as Product;
        final chatcito = listafinal[index][1] as ChatExchange;
        return ListTile(
          leading:
              CircleAvatar(backgroundImage: NetworkImage(product.images.first)),
          title: Text(product.title),
          //onTap: () {},
          onTap: () =>  context.push('/previewrequested/${ chatcito.id }'),
        );
      },
    );
  }
}