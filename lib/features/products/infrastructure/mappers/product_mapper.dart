import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/infrastructure/infraestructure.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product.dart';

class ProductMapper {
  
  static jsonToEntity( Map<String, dynamic> json )=> Product(
    id:json['id'], 
    title: json['title'],
    typeOf: json['typeOf'], 
    description: json['description'], 
    tomo: json['tomo'],
    sizeOf: json['sizeOf'],
    //gender: List<String>.from( json['genders'].map( (size) => size ) ),
    gender: json['gender'],
    demographic: json['demographic'],
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