import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchanges_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_image_scroll_behavior.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth.dart';

class OtherProductScreen extends ConsumerWidget {
  final String productId;
  const OtherProductScreen({super.key, required this.productId});

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
        appBar: AppBar(title: const Text('Detalles')),
        body: productState.isLoading
            ? const FullScreenLoader()
            : productState.errorMessage.isNotEmpty &&
                    productState.product == null
                ? ListStatusView(
                    message: productState.errorMessage,
                    onRetry: () => ref
                        .read(productProvider(productId).notifier)
                        .loadProduct(),
                  )
                : productState.product == null
                    ? const ListStatusView(
                        message: 'El producto ya no está disponible.',
                      )
                    : _OtherProductView(
                        product: productState.product!,
                        otherProductsState: otherProductsList,
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
  final List<Product> otherProductsState;
  const _OtherProductInformation(
      {required this.product, required this.otherProductsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productForm = ref.watch(productFormProvider(product));
    final customColor = Theme.of(context).primaryColor;

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
                builder: (BuildContext bottomSheetContext) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (Product product2 in otherProductsState)
                        ListTile(
                            title: Text(product2.title),
                            onTap: () {
                              showDialog(
                                  context: bottomSheetContext,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: const Text('Confirmación'),
                                      content: const Text(
                                          '¿Estás seguro de enviar la solicitud de cambio?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(dialogContext);
                                            },
                                            child: const Text(
                                                'No, me arrepiento jeje')),
                                        TextButton(
                                            onPressed: () async {
                                              Navigator.of(dialogContext).pop();
                                              final wasCreated = await ref
                                                  .read(chatExchangesProvider
                                                      .notifier)
                                                  .createChatExchange({
                                                'product1': product.id,
                                                'product2': product2.id,
                                                'requester1': product2.id,
                                              });
                                              if (!bottomSheetContext.mounted ||
                                                  !context.mounted) {
                                                return;
                                              }

                                              Navigator.pop(bottomSheetContext);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(wasCreated
                                                      ? 'Se ha enviado solicitud de conversación :D !'
                                                      : 'Error al enviar la solicitud de cambio :( !'),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                                '¡Sí! Quiero cambiar :D'))
                                      ],
                                    );
                                  });
                            }),
                    ],
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
        margin: const EdgeInsets.only(left: 15.0),
        height: (cadena == 'Descripción: ') ? 200 : 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: customColor.withAlpha(50),
            borderRadius: BorderRadius.circular(20.0)),
        child: Center(
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
      scrollBehavior: const ProductImageScrollBehavior(),
      scrollDirection: Axis.horizontal,
      controller: PageController(viewportFraction: 0.7),
      children: images.asMap().entries.map((entry) {
        final imageProvider = imageProviderForPath(entry.value);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: FadeInImage(
                imageSemanticLabel: 'Foto ${entry.key + 1} de ${images.length}',
                fit: BoxFit.cover,
                image: imageProvider,
                placeholder: const AssetImage('assets/images/no-image.jpg'),
              )),
        );
      }).toList(),
    );
  }
}
