import 'package:aplicacion_mundo_otaku/domain/entities/product_model_post.dart';
import 'package:aplicacion_mundo_otaku/infrastructure/models/local_product_model.dart';
import 'package:aplicacion_mundo_otaku/shared/data/local_manga_posts.dart';
import 'package:flutter/material.dart';



class DiscoverProvider extends ChangeNotifier {

  // TODO: Repository, DataSource,

  bool initialCharge = true;
  List<ProductModel> products = [];

  Future<void> loadNextPage() async {

    await Future.delayed( const Duration(seconds: 2) );

    final List<ProductModel> newProducts = productsPosts.map( 
      ( product ) => LocalProductModel.fromJsonMap(product).toProductModelEntity()
    ).toList();

    products.addAll( newProducts );

    initialCharge = false;
    notifyListeners();
  }
}
