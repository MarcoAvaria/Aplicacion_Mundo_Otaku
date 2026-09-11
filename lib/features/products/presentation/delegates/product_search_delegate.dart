import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final ProductsRepository repository;
  final String currentUserId;

  ProductSearchDelegate({
    required this.repository,
    required this.currentUserId,
  }) : super(searchFieldLabel: 'Buscar productos');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Limpiar búsqueda',
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Cerrar búsqueda',
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Escribe al menos dos caracteres para buscar.'),
        ),
      );
    }

    return FutureBuilder<List<Product>>(
      future: repository.searchProductByTerm(normalizedQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('No fue posible completar la búsqueda.'),
          );
        }

        final products = (snapshot.data ?? [])
            .where((product) => product.user?.id != currentUserId)
            .toList();
        if (products.isEmpty) {
          return const Center(child: Text('No se encontraron productos.'));
        }

        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: product.images.isEmpty
                    ? null
                    : imageProviderForPath(product.images.first),
                child: product.images.isEmpty
                    ? const Icon(Icons.inventory_2_outlined)
                    : null,
              ),
              title: Text(product.title),
              subtitle: Text(product.typeOf),
              onTap: () => close(context, product),
            );
          },
        );
      },
    );
  }
}
