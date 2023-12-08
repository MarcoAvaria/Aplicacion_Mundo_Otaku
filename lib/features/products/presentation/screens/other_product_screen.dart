import 'dart:io';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/forms/chat_exchange_form_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth.dart';

class OtherProductScreen extends ConsumerWidget {
  final String productId;
  const OtherProductScreen({super.key, required this.productId});
  void showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto actualizado')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider(productId));
    final productsState = ref.watch(productsProvider);
    final authState = ref.watch(authProvider);
    final List<Product> otherProductsList = <Product>[];
    for (Product product in productsState.products) {
      if (authState.user?.id == product.user?.id) {
        otherProductsList.add(product);
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalles'), actions: [
          IconButton(
              onPressed: () async {
                final photoPath =
                    await CameraGalleryServiceImpl().selectPhoto();
                if (photoPath == null) return;

                ref
                    .read(productFormProvider(productState.product!).notifier)
                    .updateProductImage(photoPath); //photoPath;
              },
              icon: const Icon(Icons.photo_library_outlined)),
          IconButton(
              onPressed: () async {
                final photoPath = await CameraGalleryServiceImpl().takePhoto();
                if (photoPath == null) return;
                ref
                    .read(productFormProvider(productState.product!).notifier)
                    .updateProductImage(photoPath); //photoPath;
              },
              icon: const Icon(Icons.camera_alt_outlined)),
        ]),
        body: productState.isLoading
            ? const FullScreenLoader()
            : _OtherProductView(
                product: productState.product!,
                otherProductsState: otherProductsList),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (productState.product == null) return;

            ref
                .read(productFormProvider(productState.product!).notifier)
                .onFormSubmit()
                .then((value) {
              if (!value) return;
              showSnackbar(context); //FocusScope.of(context).unfocus();
            });
          },
          child: const Icon(Icons.save_as_outlined),
        ),
      ),
    );
  }
}

class _OtherProductView extends ConsumerWidget {
  final Product product;
  final List<Product> otherProductsState;
  const _OtherProductView(
      {required this.product, required this.otherProductsState});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productForm = ref.read(productFormProvider(product));
    final textStyles = Theme.of(context).textTheme;

    return ListView(
      children: [
        SizedBox(
          height: 450,
          width: 600,
          child: _ImageGallery(images: productForm.images),
        ),
        const SizedBox(height: 30),
        Center(
            child: Text(
          productForm.title.value,
          //style: textStyles.titleSmall,
          style: textStyles.titleLarge,
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 10),
        _OtherProductInformation(
            product: product, otherProductsState: otherProductsState),
      ],
    );
  }
}

class _OtherProductInformation extends ConsumerWidget {
  final Product product;
  //final ChatExchange conversacion;
  final List<Product> otherProductsState;
  const _OtherProductInformation(
      {required this.product, required this.otherProductsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productForm = ref.watch(productFormProvider(product));
    //final conversacionForm = ref.watch(chatExchangeFormProvider(conversacion));
    final customColor = Theme.of(context).primaryColor;
    //print(productForm.title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          methodChar(customColor, productForm.demographic, 'Demografía: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.gender, 'Género: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.typeOf, 'Tipo de producto: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.sizeOf, 'Talla de ropa: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.tomo, 'Tomo: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.tags, 'Tags: '),
          const SizedBox(height: 15),
          methodChar(customColor, productForm.description, 'Descripción: '),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (Product product2 in otherProductsState)
                          ListTile(
                              title: Text(product2.title),
                              //context.push('/chatscreen/${productForm.id}');
                              onTap: () {
                                // Cierra el BottomSheet
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirmación'),
                                        content: const Text(
                                            '¿Estás seguro de enviar la solicitud de cambio?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text(
                                                  'No, me arrepiento jeje')),
                                          TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                ChatExchange conversacion =
                                                    ChatExchange
                                                        .createWithProducts(
                                                            product1:
                                                                product.id,
                                                            product2:
                                                                product2.id,
                                                            requester1:
                                                                product2.id);

                                                final chatExchangeFormNotifier =
                                                    ref.read(
                                                  chatExchangeFormProvider(
                                                          conversacion)
                                                      .notifier,
                                                );

                                                chatExchangeFormNotifier
                                                    .onFormSubmit()
                                                    .then((value) async {
                                                  if (value) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Se ha enviado solicitud de conversación :D !'),
                                                      ),
                                                    ); // ID del formulario
                                                  } else {
                                                    Navigator.pop(context);
                                                    // Muestra un mensaje de error o realiza otras operaciones según tus necesidades.
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Error al enviar la solicitud de cambio :( !'),
                                                      ),
                                                    );
                                                  }

                                                  // TODO: Realizar otras operaciones según tus necesidades.
                                                });
                                              },
                                              child: const Text(
                                                  '¡Sí! Quiero cambiar :D'))
                                        ],
                                      );
                                    });
                              }),
                      ],
                    ),
                  );
                },
              );
            },
            child: const Text('¡Propone un cambio :)!'),
          ),
          const SizedBox(height: 100),
        ],
      ),
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
        height: (cadena == 'Descripción: ') ? 200 : 40,
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
  const _ImageGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover));
    }

    return PageView(
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
    );
  }
}
