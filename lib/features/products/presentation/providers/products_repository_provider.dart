

import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/infrastructure/infrastructure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {

  final accessToken = ref.watch( authProvider ).user?.token ?? '';

  final productsRepository = ProductRepositoryImpl(
    ProductsDatasourceImpl( accessToken: accessToken )
  );
  return productsRepository;
});