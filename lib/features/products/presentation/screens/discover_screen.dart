import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';

class DiscoverScreen extends StatelessWidget {
  
  static const String name = 'discover_screen';

  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      drawer: ConfigurationMenu( scaffoldKey: scaffoldKey ),
      appBar: CustomAppBar.customAppBar(context, '¡Cambia y descubre!'),
      body: const _DiscoverView(),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Nuevo producto'),
        icon: const Icon( Icons.add ),
        onPressed: () {
          context.push('/product/new');
        },
      ),
    );
  }
}

class _DiscoverView extends ConsumerStatefulWidget {
  const _DiscoverView();

  @override
  _DiscoverViewState createState() => _DiscoverViewState();
}

class _DiscoverViewState extends ConsumerState {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState(); 
    scrollController.addListener(() {
      if ( (scrollController.position.pixels + 400) >= scrollController.position.maxScrollExtent ) {
        ref.read(productsProvider.notifier).loadNextPage();
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

    final productsState = ref.watch( productsProvider );
    final authState = ref.watch(authProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: MasonryGridView.count(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        crossAxisCount: 1, 
        mainAxisSpacing: 20,
        crossAxisSpacing: 35,
        itemCount: productsState.products.length,
        itemBuilder: (context, index) {

          final product = productsState.products[index];
          
          if( authState.user?.id != product.user?.id ){

          return GestureDetector(
            onTap: () =>  context.push('/otherproduct/${ product.id }'),
            child: DiscoverCard(product: product)
            );
          } else {
            return Container();
          }
          //return ProductCard(product: product);
        },
      ),
    );
  }
}