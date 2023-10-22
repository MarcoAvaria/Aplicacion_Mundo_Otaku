import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ImageViewer(images: product.images ),
        Text( product.title, textAlign: TextAlign.center, ),
        const SizedBox(height: 20,)
      ],
    );
  }
}

class _ImageViewer extends StatelessWidget {

  final List<String> images;

  const _ImageViewer({ required this.images });

  @override
  Widget build(BuildContext context) {
    
    if( images.isEmpty ){
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/Ao_no_Hako_Vol_01.png', 
          fit:BoxFit.cover,
          height: 250,),
      );
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FadeInImage(
          fit: BoxFit.cover,
          height: 250,
          fadeOutDuration: const Duration(milliseconds: 300),
          fadeInDuration: const Duration(milliseconds: 300),
          image: NetworkImage( images.first ),
          placeholder: const AssetImage('assets/Komi_san_wa_Komyoshou_Desu_Vol_23.png'),
        )
      );
  }
}