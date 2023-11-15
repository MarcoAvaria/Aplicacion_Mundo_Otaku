// Generated by https://quicktype.io
import 'package:aplicacion_mundo_otaku/features/auth/domain/domain.dart';

class Product {
  String id;
  String title;
  double price;
  String description;
  String slug;
  int stock;
  List<String> sizes;
  String gender;
  List<String> tags;
  List<String> images;
  User? user;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.slug,
    required this.stock,
    required this.sizes,
    required this.gender,
    required this.tags,
    required this.images,
    this.user,
  });
}

//enum Size { XS, S, M, L, XL, XXL }

//enum Tag { SWEATSHIRT, SHIRT, HOODIE }

// class User {
//   String id;
//   Email email;
//   FullName fullName;
//   bool isActive;
//   List<Role> roles;

//   User({
//     this.id,
//     this.email,
//     this.fullName,
//     this.isActive,
//     this.roles,
//   });
// }

// enum Email { TEST1_GOOGLE_COM }

// enum FullName { JUAN_CARLOS }

// enum Role { ADMIN }
