import 'package:aplicacion_mundo_otaku/domain/entities/product.dart';
import 'package:flutter/material.dart';

class ProductScrollView extends StatelessWidget {
  
  final List<Product> products;
  
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

        //final Product productModel = products[index];

        return const Stack(
          children: [
             
          ],
        );
        
        //final ProductModel productModel = products[index];
      }
    );
  }
}