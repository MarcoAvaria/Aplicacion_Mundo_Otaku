import 'package:aplicacion_mundo_otaku/components/custom_appbar.dart';
import 'package:aplicacion_mundo_otaku/presentation/providers/discover_provider.dart';
import 'package:aplicacion_mundo_otaku/presentation/widget/shared/product_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final discoverProvider = context.watch<DiscoverProvider>();

    return Scaffold(
      appBar: CustomAppBar.myOwnMethodAppBar(context, 'Discover!'),
      body: discoverProvider.initialCharge
        ? const Center( child: CircularProgressIndicator( strokeWidth: 2 ) )
        : ProductScrollView(products: discoverProvider.products )
    );
  }
}