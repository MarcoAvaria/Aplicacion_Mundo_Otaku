import 'dart:io';

import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchange_provider.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/forms/chat_exchange_form_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';

class PreviewReceivedScreen extends ConsumerWidget {
  final String chatExchangeId;
  const PreviewReceivedScreen({super.key, required this.chatExchangeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final chatExchangeState = ref.watch(chatExchangeProvider(chatExchangeId));
    ChatExchange? chatExchangeNullable = chatExchangeState.chatExchange;

    if (chatExchangeNullable != null) {
      ChatExchange chatExchange = chatExchangeNullable;
      // Resto del código...
      return Scaffold(
        drawer: ConfigurationMenu(scaffoldKey: scaffoldKey),
        //appBar: CustomAppBar.customAppBar(context, '¡Mira la propuesta!'),
        //appBar: AppBar(title: const Text('¡Mira la propuesta!')),
        appBar: AppBar(
          title: const Text('¡Mira la propuesta!'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Use Navigator to pop the current route
              Navigator.of(context).pop();
            },
          ),
        ),
        body: chatExchangeState.isLoading
            ? const FullScreenLoader()
            : _PreviewReceivedView(
                chatExchange: chatExchange,
              ),
      );
    } else {
      // Manejar el caso en que chatExchange sea nulo
      return const Scaffold();
    }
  }
}

class _PreviewReceivedView extends ConsumerWidget {
  final ChatExchange chatExchange;
  const _PreviewReceivedView({required this.chatExchange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idUser = ref.watch(authProvider).user!.id;
    return FutureBuilder<List<Product>>(
      future: _loadProducts(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error loading products');
        } else if (snapshot.hasData) {
          final List<Product> products = snapshot.data!;
          return _buildContent(context, products, idUser, ref);
        } else {
          return const Text('No data');
        }
      },
    );
  }

  Future<List<Product>> _loadProducts(WidgetRef ref) async {
    final chatExchangeForm = ref.read(chatExchangeFormProvider(chatExchange));
    final product1 = await ref
        .read(productsRepositoryProvider)
        .getProductById(chatExchangeForm.product1);
    final product2 = await ref
        .read(productsRepositoryProvider)
        .getProductById(chatExchangeForm.product2);

    return [product1, product2];
  }

  Widget _buildContent(BuildContext context, List<Product> products,
      String idUser, WidgetRef ref) {
    //final textStyles = Theme.of(context).textTheme;
    final customColor = Theme.of(context).primaryColor;
    final Product product1 = products[0];
    final Product product2 = products[1];

    Product miProducto;
    Product otroProducto;

    if (idUser == product1.user!.id) {
      miProducto = product1;
      otroProducto = product2;
    } else {
      miProducto = product2;
      otroProducto = product1;
    }

    return ListView(
      children: [
        methodChar(customColor, otroProducto.title, 'Te ofrecen: '),
        SizedBox(
          height: 200,
          width: 600,
          child: _ImageGallery(
              images: otroProducto.images, idProducto: otroProducto.id),
        ),
        const SizedBox(height: 10),
        methodChar(customColor, miProducto.title, 'Tu entregas: '),
        SizedBox(
          height: 200,
          width: 600,
          child: _ImageGallery(
              images: miProducto.images, idProducto: miProducto.id),
        ),
        const SizedBox(height: 15),
        // Aquí puedes usar product1 y product2 según tus necesidades
        // Botones "Rechazar" y "Aceptar"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                //print('Sending request with status: rejected');
                await ref
                    .read(chatExchangeProvider(chatExchange.id).notifier)
                    .updateChatExchangeStatus('rejected');
                // Puedes realizar otras acciones después de rechazar la conversación
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                shape: const CircleBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
              ),
              child: const Text(
                'Rechazar',
                style: TextStyle(fontSize: 18),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(chatExchangeProvider(chatExchange.id).notifier)
                    .updateChatExchangeStatus('inProgress');
                // Muestra el SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Acción completada con éxito!'),
                  ),
                );
                // Puedes realizar otras acciones después de aceptar la conversación
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                shape: const CircleBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Container methodChar(Color customColor, dynamic myArg, String cadena) {
    dynamic variable = myArg;

    if (variable is Tomo) {
      Tomo variableDos = variable;
      variable = variableDos.value.toString();
    }

    variable = cadena + variable;

    return Container(
        //width: ,
        margin: const EdgeInsets.only(left: 15.0),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: customColor.withAlpha(50),
            borderRadius: BorderRadius.circular(20.0)),
        child: Center(
          //fit: BoxFit.contain,
          child: Text(
            variable,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
            softWrap: true,
          ),
        ));
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final String idProducto;
  const _ImageGallery({required this.images, required this.idProducto});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover));
    }

    return GestureDetector(
      onTap: () => context.push('/otherproduct/$idProducto'),
      child: PageView(
        scrollDirection: Axis.horizontal,
        controller: PageController(viewportFraction: 0.7),
        children: images.map((image) {
          late ImageProvider imageProvider;

          if (image.startsWith('http')) {
            imageProvider = NetworkImage(image);
          } else {
            imageProvider = FileImage(File(image));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: FadeInImage(
                  fit: BoxFit.cover,
                  image: imageProvider,
                  placeholder: const AssetImage('assets/images/no-image.jpg'),
                )),
          );
        }).toList(),
      ),
    );
  }
}
