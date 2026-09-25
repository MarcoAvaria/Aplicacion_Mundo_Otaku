import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/infrastructure/helpers/image_file_type.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_image_scroll_behavior.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/widgets/product_option_labels.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductScreen extends ConsumerWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  void showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto actualizado')));
  }

  Future<void> _addGalleryImage(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final photoPath = await CameraGalleryServiceImpl().selectPhoto();
    if (photoPath == null) return;

    try {
      final bytes = await CameraGalleryServiceImpl.readPhotoBytes(photoPath);
      detectImageFileType(bytes);
      ref
          .read(productFormProvider(product).notifier)
          .updateProductImage(photoPath);
    } on FormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    }
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          'Esta publicación se eliminará de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted =
        await ref.read(productProvider(productId).notifier).deleteProduct();
    if (!context.mounted) return;
    if (deleted) {
      ref.invalidate(productsProvider);
      context.go(AppRoutes.products);
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No fue posible eliminar el producto.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider(productId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        //appBar: CustomAppBar.myOwnMethodAppBar(context, 'Editar producto'),
        appBar: AppBar(title: const Text('Editar producto'), actions: [
          IconButton(
              tooltip: 'Agregar imagen desde galería',
              onPressed: productState.product == null
                  ? null
                  : () => _addGalleryImage(
                        context,
                        ref,
                        productState.product!,
                      ),
              icon: const Icon(Icons.photo_library_outlined)),
          IconButton(
              tooltip: 'Tomar fotografía',
              onPressed: productState.product == null
                  ? null
                  : () async {
                      final photoPath =
                          await CameraGalleryServiceImpl().takePhoto();
                      if (photoPath == null) return;
                      ref
                          .read(productFormProvider(productState.product!)
                              .notifier)
                          .updateProductImage(photoPath);
                    },
              icon: const Icon(Icons.camera_alt_outlined)),
          if (productId != 'new')
            IconButton(
              tooltip: 'Eliminar producto',
              onPressed: productState.product == null
                  ? null
                  : () => _deleteProduct(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ]),
        body: productState.isLoading
            ? const FullScreenLoader()
            : productState.errorMessage.isNotEmpty &&
                    productState.product == null
                ? ListStatusView(
                    message: productState.errorMessage,
                    onRetry: () => ref
                        .read(productProvider(productId).notifier)
                        .loadProduct(),
                  )
                : productState.product == null
                    ? const ListStatusView(
                        message: 'El producto ya no está disponible.',
                      )
                    : _ProductView(product: productState.product!),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Guardar producto',
          onPressed: productState.product == null
              ? null
              : () async {
                  final saved = await ref
                      .read(productFormProvider(productState.product!).notifier)
                      .onFormSubmit();
                  if (!context.mounted) return;
                  if (saved) {
                    showSnackbar(context);
                    return;
                  }
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No fue posible guardar el producto. Revisa tu conexión e inténtalo nuevamente.',
                      ),
                    ),
                  );
                },
          child: const Icon(Icons.save_as_outlined),
        ),
      ),
    );
  }
}

class _ProductView extends ConsumerWidget {
  final Product product;

  const _ProductView({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productForm = ref.watch(productFormProvider(product));

    final textStyles = Theme.of(context).textTheme;

    return ListView(
      children: [
        SizedBox(
          height: 250,
          width: 600,
          child: Semantics(
            container: true,
            label: 'Imágenes del producto: ${productForm.images.length}',
            child: _ImageGallery(images: productForm.images),
          ),
        ),
        const SizedBox(height: 10),
        Center(
            child: Text(
          productForm.title.value,
          style: textStyles.titleSmall,
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 10),
        _ProductInformation(product: product),
      ],
    );
  }
}

class _ProductInformation extends ConsumerWidget {
  final Product product;
  const _ProductInformation({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productForm = ref.watch(productFormProvider(product));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Generales'),
          const SizedBox(height: 15),
          CustomProductField(
            isTopField: true,
            label: 'Nombre',
            initialValue: productForm.title.value,
            onChanged:
                ref.read(productFormProvider(product).notifier).onTitleChanged,
            errorMessage: productForm.title.errorMessage,
          ),
          const SizedBox(height: 15),
          const Text('Demografía'),
          const SizedBox(height: 5),
          _DemographicSelector(
            //selectedGender: productForm.gender,
            selectedDemographic: productForm.demographic,
            onDemographicChanged: ref
                .read(productFormProvider(product).notifier)
                .onDemographicChanged,
          ),
          const SizedBox(height: 15),
          const Text('Tipo'),
          const SizedBox(height: 5),
          _TypeSelector(
            selectedType: productForm.typeOf,
            //selectedDemographic: productForm.demographic,
            onTypeChanged:
                ref.read(productFormProvider(product).notifier).onTypeChanged,
          ),
          const SizedBox(height: 15),
          const Text('Género'),
          const SizedBox(height: 5),
          _GenderSelector(
            selectedGenders: productForm.gender,
            //selectedDemographic: productForm.demographic,
            onGendersChanged:
                ref.read(productFormProvider(product).notifier).onGenderChanged,
          ),
          const SizedBox(height: 15),
          CustomProductField(
            isTopField: true,
            label: 'Volumen | Tomo',
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            //initialValue: productForm.tomo.toString(),
            initialValue: productForm.tomo.value.toString(),
            onChanged: (value) => ref
                .read(productFormProvider(product).notifier)
                .onStockChanged(value),
            errorMessage: productForm.tomo.errorMessage,
          ),
          const SizedBox(height: 15),
          const Text('Talla de ropa'),
          const SizedBox(height: 5),
          _SizeSelector(
            selectedSizes: productForm.sizeOf,
            onSizesChanged:
                ref.read(productFormProvider(product).notifier).onSizeChanged,
          ),
          const SizedBox(height: 55),
          CustomProductField(
            maxLines: 6,
            label: 'Descripción',
            keyboardType: TextInputType.multiline,
            initialValue: product.description,
            onChanged: ref
                .read(productFormProvider(product).notifier)
                .onDescriptionChanged,
          ),
          CustomProductField(
            isBottomField: true,
            maxLines: 2,
            label: 'Tags (Separados por coma)',
            keyboardType: TextInputType.multiline,
            initialValue: product.tags.join(', '),
            onChanged:
                ref.read(productFormProvider(product).notifier).onTagsChanged,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final String selectedSizes;
  final List<String> sizes = const [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    'Ninguno'
  ];

  final void Function(String selectedSizes) onSizesChanged;

  const _SizeSelector({
    required this.selectedSizes,
    required this.onSizesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12), // Ajusta el relleno según sea necesario
        decoration: BoxDecoration(
          //color: Colors.grey[200],
          color: customColor.withAlpha(50), // Color de fondo del DropdownButton
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButton<String>(
          value: selectedSizes,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onSizesChanged(newValue);
            }
          },
          //style: const TextStyle(fontSize: 12),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface), // Estilo del texto
          dropdownColor: Theme.of(context).colorScheme.surface,
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: sizes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(productOptionLabel(value),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface)) // Color del texto dentro del DropdownButton
                );
          }).toList(),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String selectedType;
  final void Function(String selectedType) onTypeChanged;

  final List<String> typesOf = const [
    'Ropa',
    'Manga',
    'Taza',
    'Otros',
  ];

  const _TypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12), // Ajusta el relleno según sea necesario
        decoration: BoxDecoration(
          //color: Colors.grey[200],
          color: customColor.withAlpha(50), // Color de fondo del DropdownButton
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButton<String>(
          value: selectedType,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onTypeChanged(newValue);
            }
          },
          //style: const TextStyle(fontSize: 12),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface), // Estilo del texto
          dropdownColor: Theme.of(context).colorScheme.surface,
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: typesOf.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(productOptionLabel(value),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface)) // Color del texto dentro del DropdownButton
                );
          }).toList(),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String selectedGenders;
  final void Function(String selectedGenders) onGendersChanged;

  final List<String> genders = const [
    'Accion peleas',
    'Comedia',
    'Slice of life',
    'Spokon',
    'Magical Girls Maho Shojo',
    'Yuri',
    'Yaoi',
    'Romcom',
    'Romance',
    'Ecchi',
    'Hentai',
    'Gore Terror',
    'Isekai',
    'Ninguno'
  ];

  const _GenderSelector({
    required this.selectedGenders,
    required this.onGendersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12), // Ajusta el relleno según sea necesario
        decoration: BoxDecoration(
          //color: Colors.grey[200],
          color: customColor.withAlpha(50), // Color de fondo del DropdownButton
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButton<String>(
          value: selectedGenders,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onGendersChanged(newValue);
            }
          },
          //style: const TextStyle(fontSize: 12),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface), // Estilo del texto
          dropdownColor: Theme.of(context).colorScheme.surface,
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: genders.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(productOptionLabel(value),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface)) // Color del texto dentro del DropdownButton
                );
          }).toList(),
        ),
      ),
    );
  }
}

class _DemographicSelector extends StatelessWidget {
  final String selectedDemographic;
  final void Function(String selectedDemographic) onDemographicChanged;

  final List<String> demographics = const [
    'Shonen',
    'Seinen',
    'Josei',
    'Shojo',
    'Komodo'
  ];

  const _DemographicSelector(
      {required this.selectedDemographic, required this.onDemographicChanged});

  @override
  Widget build(BuildContext context) {
    final customColor = Theme.of(context).primaryColor;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12), // Ajusta el relleno según sea necesario
        decoration: BoxDecoration(
          //color: Colors.grey[200],
          color: customColor.withAlpha(50), // Color de fondo del DropdownButton
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButton<String>(
          value: selectedDemographic,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onDemographicChanged(newValue);
            }
          },
          //style: const TextStyle(fontSize: 12),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface), // Estilo del texto
          dropdownColor: Theme.of(context).colorScheme.surface,
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: demographics.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(productOptionLabel(value),
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface)) // Color del texto dentro del DropdownButton
                );
          }).toList(),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  const _ImageGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover));
    }

    return PageView(
      scrollBehavior: const ProductImageScrollBehavior(),
      scrollDirection: Axis.horizontal,
      controller: PageController(viewportFraction: 0.7),
      children: images.asMap().entries.map((entry) {
        final imageProvider = imageProviderForPath(entry.value);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: FadeInImage(
                imageSemanticLabel: 'Foto ${entry.key + 1} de ${images.length}',
                fit: BoxFit.cover,
                image: imageProvider,
                placeholder: const AssetImage('assets/images/no-image.jpg'),
              )),
        );
      }).toList(),
    );
  }
}
