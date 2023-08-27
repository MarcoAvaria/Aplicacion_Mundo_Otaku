import 'package:aplicacion_mundo_otaku/domain/entities/product_model_post.dart';
import 'package:flutter/material.dart';

class ProductScrollView extends StatelessWidget {
  
  final List<ProductModel> products;
  
  const ProductScrollView({
    super.key, 
    required this.products
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index){
        
        //final ProductModel productModel = products[index];
      }
    );
  }
}