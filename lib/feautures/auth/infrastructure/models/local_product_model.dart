import '../../domain/entities/product.dart';

class LocalProductModel {
  final int id;
  final String tipo;
  final String franquicia;
  int? volumen;
  String? descripcion;
  int? precio;
  String? path;

  LocalProductModel({
    required this.id,
    required this.tipo,
    required this.franquicia,
    this.volumen,
    this.descripcion,
    this.precio,
    this.path,
  });

  factory LocalProductModel.fromJsonMap(Map<String, dynamic> json) => LocalProductModel(
    id: json['id'] , 
    tipo: json['tipo'], 
    franquicia: json['franquicia'],
    volumen: json['volumen'],
    descripcion: json['descripcion'],
    precio: json['precio'],
    path: json['path']
  );

  Product toProductModelEntity() => Product(
    id: id,
    tipo: tipo,
    franquicia: franquicia,
    volumen: volumen,
    descripcion: descripcion,
    precio: precio,
    path: path
  );
} 