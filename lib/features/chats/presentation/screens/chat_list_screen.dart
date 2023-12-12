import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aplicacion_mundo_otaku/features/auth/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
//import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  static const String name = 'chat_list_screen';
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    late SocketService socketService;
    return Scaffold(
      drawer: ConfigurationMenu(scaffoldKey: scaffoldKey),
      appBar: CustomAppBar.customAppBar(context, '¡Chats!'),
      body: _ChatListView(
        onSocketServiceCreated: (service) {
          // Asignar el valor del socketService
          socketService = service;
        },
      ),
    );
  }
}

class _ChatListView extends ConsumerStatefulWidget {
  final Function(SocketService) onSocketServiceCreated;

  
  const _ChatListView({required this.onSocketServiceCreated});
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<_ChatListView> {
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
    final chatExchangesState = ref.watch(chatExchangesProvider);
    List<ChatExchange> listaTotalChat = chatExchangesState.chatExchanges;
    final productsState = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);
    List<Product> listaDeProductos = productsState.products
        .where((product) => product.user?.id != authState.user?.id)
        .toList();

    /*
    for (ChatExchange conversacion in listaTotalChat) {
      for (Product miProducto in misProductos) {
        if (((miProducto.id == conversacion.product1) &&
                (miProducto.id != conversacion.requester1)) &&
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
    */

    List<List<Object>> listafinal = [];

    List<Product> filteredProducts = listaDeProductos
        .where((product1) => listaTotalChat.any((chatExchange) =>
            ((product1.id == chatExchange.product1) ||
                (product1.id == chatExchange.product2)) &&
            (chatExchange.status == 'inProgress')))
        .toList();

    for (Product miProducto in filteredProducts) {
      for (ChatExchange conversacion in listaTotalChat) {
        if (((miProducto.id == conversacion.product1) ||
                (miProducto.id == conversacion.product2)) &&
            (conversacion.status == 'inProgress')) {
          if (conversacion.product1 == miProducto.id) {
            listafinal.add([
              miProducto,
              conversacion,
            ]);
          } else {
            listafinal.add([
              miProducto,
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
        final conversacion = listafinal[index][1] as ChatExchange;
        String miProductId;
        String otroProductId;
        if( product.id == conversacion.product1 ) {
          miProductId = conversacion.product2;
          otroProductId = conversacion.product1; 
        } else {
          miProductId = conversacion.product1;
          otroProductId = conversacion.product2;
        }
        final socketService = SocketService(
          tokencito: miProductId, // Reemplaza lógica para obtener el token
          chatExchangeId: conversacion.id, // Reemplaza con tu lógica para obtener el chat exchange id
          sendBy: miProductId, // Reemplaza con tu lógica para obtener el send by
        );

        // Llamar al callback para notificar que el SocketService ha sido creado
        widget.onSocketServiceCreated(socketService);

        return ListTile(
          leading:
              CircleAvatar(backgroundImage: NetworkImage(product.images.first)),
          title: Text(product.title),
          onTap: () => context.push(
            '/chatscreen/${conversacion.id}/$miProductId/$otroProductId',

          ),
        );
      },
    );
  }
}
