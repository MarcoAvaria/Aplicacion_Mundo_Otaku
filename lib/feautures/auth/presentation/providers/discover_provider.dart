import 'package:aplicacion_mundo_otaku/feautures/auth/domain/entities/product.dart';
import 'package:aplicacion_mundo_otaku/feautures/auth/infrastructure/models/local_product_model.dart';
import 'package:aplicacion_mundo_otaku/feautures/data/local_manga_posts.dart';
import 'package:flutter/material.dart';



class DiscoverProvider extends ChangeNotifier {

  // TO DO: Repository, DataSource,

  bool initialCharge = true;
  List<Product> products = [];

  Future<void> loadNextPage() async {

    await Future.delayed( const Duration(seconds: 2) );

    final List<Product> newProducts = productsPosts.map( 
      ( product ) => LocalProductModel.fromJsonMap(product).toProductModelEntity()
    ).toList();

    products.addAll( newProducts );

    initialCharge = false;
    notifyListeners();
  }
}
