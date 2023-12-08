import 'dart:io';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductScreen extends ConsumerWidget {
  final String productId;

  const ProductScreen({super.key, required this.productId});

  void showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Producto actualizado')));
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
              onPressed: () async {
                final photoPath =
                    await CameraGalleryServiceImpl().selectPhoto();
                if (photoPath == null) return;

                ref
                    .read(productFormProvider(productState.product!).notifier)
                    .updateProductImage(photoPath);
                //photoPath;
              },
              icon: const Icon(Icons.photo_library_outlined)),
          IconButton(
              onPressed: () async {
                final photoPath = await CameraGalleryServiceImpl().takePhoto();
                if (photoPath == null) return;
                ref
                    .read(productFormProvider(productState.product!).notifier)
                    .updateProductImage(photoPath);
                //photoPath;
              },
              icon: const Icon(Icons.camera_alt_outlined)),
        ]),
        body: productState.isLoading
            ? const FullScreenLoader()
            : _ProductView(product: productState.product!),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (productState.product == null) return;

            ref
                .read(productFormProvider(productState.product!).notifier)
                .onFormSubmit()
                .then((value) {
              if (!value) return;
              showSnackbar(context);
              //FocusScope.of(context).unfocus();
            });
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
          child: _ImageGallery(images: productForm.images),
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
                .onStockChanged(int.tryParse(value) ?? -1),
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
  final List<String> sizes = const ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL','Ninguno'];

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
          style: const TextStyle(
              fontSize: 12, color: Colors.black), // Estilo del texto
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: sizes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors
                            .black)) // Color del texto dentro del DropdownButton
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
          style: const TextStyle(
              fontSize: 12, color: Colors.black), // Estilo del texto
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: typesOf.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors
                            .black)) // Color del texto dentro del DropdownButton
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
          style: const TextStyle(
              fontSize: 12, color: Colors.black), // Estilo del texto
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: genders.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors
                            .black)) // Color del texto dentro del DropdownButton
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
          style: const TextStyle(
              fontSize: 12, color: Colors.black), // Estilo del texto
          //iconSize: 24, // Tamaño del icono
          //elevation: 16, // Elevación del menú desplegable
          items: demographics.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors
                            .black)) // Color del texto dentro del DropdownButton
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
      scrollDirection: Axis.horizontal,
      controller: PageController(viewportFraction: 0.7),
      children: images.map((image) {
        late ImageProvider imageProvider;

        if (image.startsWith('http')) {
          imageProvider = NetworkImage(image);
        } else {
          imageProvider = FileImage(File(image));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: FadeInImage(
                fit: BoxFit.cover,
                image: imageProvider,
                placeholder: const AssetImage('assets/images/no-image.jpg'),
              )),
        );
      }).toList(),
    );
  }
}