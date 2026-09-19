import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/domain/entities/chat_exchange.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/providers/chat_exchange_provider.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';
import 'package:aplicacion_mundo_otaku/config/config.dart';

class PreviewRequestedScreen extends ConsumerWidget {
  final String chatExchangeId;
  const PreviewRequestedScreen({super.key, required this.chatExchangeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final chatExchangeState = ref.watch(chatExchangeProvider(chatExchangeId));
    final chatExchange = chatExchangeState.chatExchange;

    return Scaffold(
      drawer: StyledNavigationDrawer(scaffoldKey: scaffoldKey),
      appBar: AppBar(
        title: const Text('¡Mira la propuesta!'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: chatExchangeState.isLoading
          ? const FullScreenLoader()
          : chatExchangeState.errorMessage.isNotEmpty && chatExchange == null
              ? ListStatusView(
                  message: chatExchangeState.errorMessage,
                  onRetry: () => ref
                      .read(chatExchangeProvider(chatExchangeId).notifier)
                      .loadChatExchange(),
                )
              : chatExchange == null
                  ? const ListStatusView(
                      message: 'La solicitud ya no está disponible.',
                    )
                  : _PreviewRequestedView(chatExchange: chatExchange),
    );
  }
}

class _PreviewRequestedView extends ConsumerStatefulWidget {
  final ChatExchange chatExchange;
  const _PreviewRequestedView({required this.chatExchange});

  @override
  ConsumerState<_PreviewRequestedView> createState() =>
      _PreviewRequestedViewState();
}

class _PreviewRequestedViewState extends ConsumerState<_PreviewRequestedView> {
  late Future<List<Product>> productsFuture;
  ChatExchange get chatExchange => widget.chatExchange;

  @override
  void initState() {
    super.initState();
    productsFuture = _loadProducts(ref);
  }

  void retryProducts() {
    setState(() => productsFuture = _loadProducts(ref));
  }

  @override
  Widget build(BuildContext context) {
    final idUser = ref.watch(authProvider).user!.id;
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoader();
        } else if (snapshot.hasError) {
          return ListStatusView(
            message: 'No fue posible cargar los productos de la solicitud.',
            onRetry: retryProducts,
          );
        } else if (snapshot.hasData) {
          final List<Product> products = snapshot.data!;
          return _buildContent(context, products, idUser, ref);
        } else {
          return const ListStatusView(
            message: 'Los productos de la solicitud ya no están disponibles.',
          );
        }
      },
    );
  }

  Future<List<Product>> _loadProducts(WidgetRef ref) async {
    final product1 = await ref
        .read(productsRepositoryProvider)
        .getProductById(chatExchange.product1);
    final product2 = await ref
        .read(productsRepositoryProvider)
        .getProductById(chatExchange.product2);

    return [product1, product2];
  }

  Widget _buildContent(BuildContext context, List<Product> products,
      String idUser, WidgetRef ref) {
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
        methodChar(customColor, miProducto.title, 'Tu ofreces: '),
        SizedBox(
          height: 200,
          width: 600,
          child: _ImageGallery(
              images: miProducto.images, idProducto: miProducto.id),
        ),
        const SizedBox(height: 10),
        methodChar(customColor, otroProducto.title, 'Tu recibes: '),
        SizedBox(
          height: 200,
          width: 600,
          child: _ImageGallery(
              images: otroProducto.images, idProducto: otroProducto.id),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                final wasUpdated = await ref
                    .read(chatExchangeProvider(chatExchange.id).notifier)
                    .updateChatExchangeStatus('abort');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(wasUpdated
                        ? 'Se ha cancelado la solicitud'
                        : 'No fue posible cancelar la solicitud.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                shape: const CircleBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
              ),
              child: const Text(
                'Cancelar',
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
        margin: const EdgeInsets.only(left: 15.0),
        height: 50,
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
      onTap: () => context.push(AppRoutes.otherProduct(idProducto)),
      child: PageView(
        scrollDirection: Axis.horizontal,
        controller: PageController(viewportFraction: 0.7),
        children: images.map((image) {
          final imageProvider = imageProviderForPath(image);

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
