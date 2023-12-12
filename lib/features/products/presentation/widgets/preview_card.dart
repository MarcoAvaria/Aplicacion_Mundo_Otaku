import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:flutter/material.dart';

class PreviewCard extends StatelessWidget {
  
  final Product product;

  const PreviewCard({
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

  Container methodChar(Color customColor, String cadena) {

    return Container(
        //width: ,
        margin: const EdgeInsets.only(left: 15.0),
        height: (cadena == 'Descripción: ') ? 200 : 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: customColor.withAlpha(50),
            borderRadius: BorderRadius.circular(20.0)),
        child: Center(
          //fit: BoxFit.contain,
          child: Text(
            cadena,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
            softWrap: true,
          ),
        ));
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