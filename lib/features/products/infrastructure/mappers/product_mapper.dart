

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';

class ProductMapper {
  
  static jsonToEntity( Map<String, dynamic> json )=> Product(
    id:json['id'], 
    title: json['title'], 
    price: double.parse( json['price'].toString() ), 
    description: json['description'], 
    slug: json['slug'], 
    stock: json['stock'], 
    sizes: List<String>.from( json['sizes'].map( (size) => size ) ), 
    gender: json['gender'], 
    tags: List<String>.from( json['tags'].map( (tag) => tag ) ),
    images: List<String>.from(
      json['images'].map(
        (image) => image.startsWith('http')
        ? image
        : '${ Environment.apiUrl }/files/product/$image',
      )
    ), 
    user: UserMapper.userJsonToEntity( json['user'] )
  );
}