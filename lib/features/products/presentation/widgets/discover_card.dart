import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';

class DiscoverCard extends StatelessWidget {
  
  final Product product;

  const DiscoverCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ImageViewer(images: product.images ),
        const SizedBox(height: 10),
        Text( 
          product.title,
          textAlign: TextAlign.center, 
          style: const TextStyle(
            fontSize: 20,
          )  
        ),
        const SizedBox(height: 50),
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
        child: Image.asset('assets/images/no-image.jpg', 
          fit:BoxFit.cover,
          height: 400,),
      );
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FadeInImage(
          fit: BoxFit.cover,
          height: 400,
          fadeOutDuration: const Duration(milliseconds: 100),
          fadeInDuration: const Duration(milliseconds: 200),
          image: NetworkImage( images.first ),
          placeholder: const AssetImage('assets/images/no-image.jpg'),
        )
      );
  }
}