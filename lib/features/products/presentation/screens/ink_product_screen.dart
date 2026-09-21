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

/// "Editar producto" en la dirección "Tinta y Neón".
///
/// Conserva el comportamiento de `ProductScreen` (carga, edición, guardado,
/// imágenes y borrado) y cambia solo la presentación: tarjetas con borde y
/// sombra dura en vez de campos flotantes, y selección por chips en vez de
/// `DropdownButton`, para seguir el mismo lenguaje que `InkProductsScreen` /
/// `InkOtherProductScreen`. El original se conserva intacto.
class InkProductScreen extends ConsumerWidget {
  static const String name = 'ink_product_screen';

  final String productId;

  const InkProductScreen({super.key, required this.productId});

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      _showSnackbar(context, error.message.toString());
    }
  }

  Future<void> _takePhoto(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final photoPath = await CameraGalleryServiceImpl().takePhoto();
    if (photoPath == null) return;
    ref
        .read(productFormProvider(product).notifier)
        .updateProductImage(photoPath);
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

    _showSnackbar(context, 'No fue posible eliminar el producto.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = InkTokens.of(context);
    final productState = ref.watch(productProvider(productId));
    final product = productState.product;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: tokens.paper,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                tokens: tokens,
                showDelete: productId != 'new',
                onBack: () => Navigator.of(context).maybePop(),
                onGallery: product == null
                    ? null
                    : () => _addGalleryImage(context, ref, product),
                onCamera: product == null
                    ? null
                    : () => _takePhoto(context, ref, product),
                onDelete: product == null
                    ? null
                    : () => _deleteProduct(context, ref),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: productState.isLoading
                    ? const FullScreenLoader()
                    : productState.errorMessage.isNotEmpty && product == null
                        ? ListStatusView(
                            message: productState.errorMessage,
                            onRetry: () => ref
                                .read(productProvider(productId).notifier)
                                .loadProduct(),
                          )
                        : product == null
                            ? const ListStatusView(
                                message: 'El producto ya no está disponible.',
                              )
                            : _FormView(tokens: tokens, product: product),
              ),
              if (product != null)
                _SaveBar(
                  tokens: tokens,
                  product: product,
                  onShowSnackbar: (message) =>
                      _showSnackbar(context, message),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tokens,
    required this.showDelete,
    required this.onBack,
    required this.onGallery,
    required this.onCamera,
    required this.onDelete,
  });

  final InkTokens tokens;
  final bool showDelete;
  final VoidCallback onBack;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          _SquareIconButton(
            tokens: tokens,
            icon: Icons.arrow_back,
            label: 'Volver',
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editar producto',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.displayStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: tokens.text,
              ),
            ),
          ),
          _SquareIconButton(
            tokens: tokens,
            icon: Icons.photo_library_outlined,
            label: 'Agregar imagen desde galería',
            onTap: onGallery,
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            tokens: tokens,
            icon: Icons.camera_alt_outlined,
            label: 'Tomar fotografía',
            onTap: onCamera,
          ),
          if (showDelete) ...[
            const SizedBox(width: 8),
            _SquareIconButton(
              tokens: tokens,
              icon: Icons.delete_outline,
              label: 'Eliminar producto',
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final InkTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Material(
          color: tokens.panel,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: tokens.ink, width: 2),
              ),
              child: Icon(icon, size: 19, color: tokens.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormView extends ConsumerWidget {
  const _FormView({required this.tokens, required this.product});

  final InkTokens tokens;
  final Product product;

  static const _demographics = [
    'Shonen',
    'Seinen',
    'Josei',
    'Shojo',
    'Komodo',
  ];
  static const _types = ['Ropa', 'Manga', 'Taza', 'Otros'];
  static const _genders = [
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
    'Ninguno',
  ];
  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Ninguno'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productFormProvider(product).notifier);
    final formState = ref.watch(productFormProvider(product));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        _CoverBox(tokens: tokens, images: formState.images),
        const SizedBox(height: 16),
        _Panel(
          tokens: tokens,
          title: 'Generales',
          children: [
            _InkTextField(
              tokens: tokens,
              label: 'Nombre',
              initialValue: formState.title.value,
              errorMessage: formState.title.errorMessage,
              onChanged: notifier.onTitleChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          tokens: tokens,
          title: 'Clasificación',
          children: [
            // Grilla compacta como en la maqueta de Claude Design
            // (Form-Editar): cada casilla muestra la opción elegida y abre
            // una hoja con todas las opciones al tocarla.
            _GridRow(
              left: _SelectBox(
                tokens: tokens,
                label: 'Demografía',
                options: _demographics,
                selected: formState.demographic,
                onSelected: notifier.onDemographicChanged,
              ),
              right: _SelectBox(
                tokens: tokens,
                label: 'Tipo',
                options: _types,
                selected: formState.typeOf,
                onSelected: notifier.onTypeChanged,
              ),
            ),
            _GridRow(
              left: _SelectBox(
                tokens: tokens,
                label: 'Género',
                options: _genders,
                selected: formState.gender,
                onSelected: notifier.onGenderChanged,
              ),
              right: _InkTextField(
                tokens: tokens,
                compact: true,
                label: 'Volumen | Tomo',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                initialValue: formState.tomo.value.toString(),
                errorMessage: formState.tomo.errorMessage,
                onChanged: (value) =>
                    notifier.onStockChanged(int.tryParse(value) ?? -1),
              ),
            ),
            _SelectBox(
              tokens: tokens,
              label: 'Talla de ropa',
              options: _sizes,
              selected: formState.sizeOf,
              onSelected: notifier.onSizeChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Panel(
          tokens: tokens,
          title: 'Descripción y etiquetas',
          children: [
            _InkTextField(
              tokens: tokens,
              label: 'Descripción',
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              initialValue: product.description,
              onChanged: notifier.onDescriptionChanged,
            ),
            _InkTextField(
              tokens: tokens,
              label: 'Tags (Separados por coma)',
              maxLines: 2,
              keyboardType: TextInputType.multiline,
              initialValue: product.tags.join(', '),
              onChanged: notifier.onTagsChanged,
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Portada del formulario: sin la placa "No image" rota — cuando no hay
/// fotos muestra una zona con trama halftone e instrucciones, en vez del
/// `assets/images/no-image.jpg` crudo.
class _CoverBox extends StatefulWidget {
  const _CoverBox({required this.tokens, required this.images});

  final InkTokens tokens;
  final List<String> images;

  @override
  State<_CoverBox> createState() => _CoverBoxState();
}

class _CoverBoxState extends State<_CoverBox> {
  // Un solo controlador: si se creara en `build`, cada tecla en el formulario
  // reconstruiría el carrusel y lo devolvería a la primera foto.
  final PageController _controller = PageController(viewportFraction: 0.86);
  int _page = 0;

  InkTokens get tokens => widget.tokens;
  List<String> get images => widget.images;

  @override
  void didUpdateWidget(covariant _CoverBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al agregar una foto se muestra la nueva, para confirmar que llegó.
    if (oldWidget.images.isNotEmpty &&
        widget.images.length > oldWidget.images.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.animateToPage(
          widget.images.length - 1,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Imágenes del producto: ${images.length}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
          ],
        ),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: tokens.avatarWash,
            border: Border.all(color: tokens.ink, width: tokens.borderWidth),
          ),
          child: images.isEmpty ? _empty() : _gallery(),
        ),
      ),
    );
  }

  Widget _empty() {
    return CustomPaint(
      painter: HalftonePainter(
        color: tokens.halftone,
        spacing: 9,
        opacity: 0.22,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 30,
              color: tokens.halftone,
            ),
            const SizedBox(height: 8),
            Container(
              color: tokens.paper,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Agrega la portada con los íconos de arriba',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gallery() {
    final page = _page.clamp(0, images.length - 1);

    return Stack(
      children: [
        Positioned.fill(
          child: PageView(
            controller: _controller,
            scrollBehavior: const ProductImageScrollBehavior(),
            onPageChanged: (index) => setState(() => _page = index),
            children: [
              for (var index = 0; index < images.length; index++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FadeInImage(
                    imageSemanticLabel: 'Foto ${index + 1} de ${images.length}',
                    fit: BoxFit.cover,
                    image: imageProviderForPath(images[index]),
                    placeholder:
                        const AssetImage('assets/images/no-image.jpg'),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1)
          Positioned(
            right: 10,
            bottom: 10,
            child: ExcludeSemantics(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.panel,
                  border: Border.all(color: tokens.ink, width: 2),
                ),
                child: Text(
                  '${page + 1} / ${images.length}',
                  style: AppFonts.displayStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tokens.text,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tarjeta con sección: mismo patrón de borde y sombra dura que el resto de
/// la dirección "Tinta y Neón" (ver `InkHardButton`, `_Cover` en
/// `InkOtherProductScreen`).
class _Panel extends StatelessWidget {
  const _Panel({
    required this.tokens,
    required this.title,
    required this.children,
  });

  final InkTokens tokens;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: tokens.shadow, offset: const Offset(4, 4)),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.panel,
          border: Border.all(color: tokens.ink, width: tokens.borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: tokens.halftone,
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0)
                SizedBox(height: children[index] is _InkTextField ? 16 : 8),
              children[index],
            ],
          ],
        ),
      ),
    );
  }
}

/// Campo de texto de ancho completo con borde inferior, coherente con la
/// barra de búsqueda de `InkDiscoverScreen` en vez del campo flotante de
/// `CustomProductField`.
class _InkTextField extends StatefulWidget {
  const _InkTextField({
    required this.tokens,
    required this.label,
    required this.initialValue,
    this.errorMessage,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
    this.compact = false,
  });

  /// Casilla de la grilla: borde propio, etiqueta pequeña adentro.
  final bool compact;
  final InkTokens tokens;
  final String label;
  final String initialValue;
  final String? errorMessage;
  final TextInputType keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<_InkTextField> createState() => _InkTextFieldState();
}

class _InkTextFieldState extends State<_InkTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode()..addListener(_synchronizeWhenFocusIsLost);
  }

  void _synchronizeWhenFocusIsLost() {
    if (widget.compact && mounted) setState(() {});
    if (!_focusNode.hasFocus) {
      widget.onChanged?.call(_controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant _InkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_synchronizeWhenFocusIsLost)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  static OutlineInputBorder _box(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: color, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final errorColor = Theme.of(context).colorScheme.error;

    final compact = widget.compact;
    final labelStyle = compact
        ? _SelectBox.labelStyle(tokens)
        : TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.3,
      color: tokens.muted,
    );
    final none = compact ? InputBorder.none : null;

    // La etiqueta va dentro de `InputDecoration` y no como un `Text` aparte:
    // así Flutter la usa como nombre accesible del campo, y los recorridos
    // Playwright (`e2e/tests/full-journey.spec.js`) lo buscan con
    // `getByLabel('Nombre')`, `getByLabel('Volumen | Tomo')`, etc. Se ve en
    // mayúsculas, pero `semanticsLabel` conserva el texto original.
    final field = TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onFieldSubmitted: (value) => widget.onChanged?.call(value),
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          cursorColor: tokens.halftone,
          style: compact
              ? _SelectBox.valueStyle(tokens)
              : AppFonts.bodyStyle(
                  fontSize: 15,
                  letterSpacing: 0,
                  color: tokens.text,
                ),
          decoration: InputDecoration(
            isDense: true,
            filled: !compact,
            fillColor: tokens.paper,
            label: Text(
              widget.label.toUpperCase(),
              semanticsLabel: widget.label,
            ),
            labelStyle: labelStyle,
            floatingLabelStyle: MaterialStateTextStyle.resolveWith(
              (states) => labelStyle.copyWith(
                color: states.contains(MaterialState.focused)
                    ? tokens.halftone
                    : tokens.muted,
              ),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: widget.errorMessage,
            contentPadding: compact
                ? const EdgeInsets.only(top: 4)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            // Todos los estados se fijan aquí: si se deja alguno, el tema
            // editorial vuelve a meter su borde redondeado.
            border: none ?? _box(tokens.ink),
            enabledBorder: none ?? _box(tokens.ink),
            disabledBorder: none ?? _box(tokens.ink),
            focusedBorder: none ?? _box(tokens.halftone),
            errorBorder: none ?? _box(errorColor),
            focusedErrorBorder: none ?? _box(errorColor),
          ),
        );

    if (!compact) {
      return Padding(padding: const EdgeInsets.only(top: 6), child: field);
    }
    return _GridCell(
      tokens: tokens,
      highlighted: _focusNode.hasFocus,
      child: field,
    );
  }
}

/// Dos casillas del mismo alto, lado a lado.
class _GridRow extends StatelessWidget {
  const _GridRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      ),
    );
  }
}

/// Marco común de las casillas de "Clasificación".
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.tokens,
    required this.child,
    this.highlighted = false,
  });

  final InkTokens tokens;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border.all(
          color: highlighted ? tokens.halftone : tokens.ink,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

/// Casilla que muestra la opción elegida y abre la lista completa en una
/// hoja inferior, en vez del `DropdownButton` redondeado de Material.
class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.tokens,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final InkTokens tokens;
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  static TextStyle labelStyle(InkTokens tokens) => TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: tokens.muted,
      );

  static TextStyle valueStyle(InkTokens tokens) => AppFonts.bodyStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: tokens.text,
      );

  Future<void> _open(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: tokens.paper,
      shape: Border(top: BorderSide(color: tokens.ink, width: 2)),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.displayStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final option in options)
                    _Chip(
                      tokens: tokens,
                      label: productOptionLabel(option),
                      selected: option == selected,
                      onTap: () => Navigator.pop(sheetContext, option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null) onSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${productOptionLabel(selected)}',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _open(context),
            child: _GridCell(
              tokens: tokens,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: labelStyle(tokens)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productOptionLabel(selected),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: valueStyle(tokens),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: tokens.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

/// Opción de la hoja de selección (paleta `chipSelected` de `InkTokens`).
class _Chip extends StatelessWidget {
  const _Chip({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final InkTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.chipSelected : tokens.panel,
        child: InkWell(
          onTap: onTap,
          // Sin `alignment`: con él, el Container se estira a todo el ancho
          // del Wrap y cada chip queda en su propia fila.
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? tokens.chipSelectedBorder : tokens.ink,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? tokens.chipSelectedText : tokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de guardado inferior, mismo patrón que `_ProposeBar` en
/// `InkOtherProductScreen`: reemplaza el FAB circular original.
///
/// Mientras se guarda, el botón no acepta más toques: el FAB original permitía
/// enviar el mismo formulario dos veces con un doble toque.
class _SaveBar extends ConsumerStatefulWidget {
  const _SaveBar({
    required this.tokens,
    required this.product,
    required this.onShowSnackbar,
  });

  final InkTokens tokens;
  final Product product;
  final ValueChanged<String> onShowSnackbar;

  @override
  ConsumerState<_SaveBar> createState() => _SaveBarState();
}

class _SaveBarState extends ConsumerState<_SaveBar> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final saved = await ref
        .read(productFormProvider(widget.product).notifier)
        .onFormSubmit();
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved) {
      // Un producto nuevo guardado sigue siendo 'new' en esta pantalla: si se
      // quedara abierta, un segundo "Guardar" publicaría un duplicado. Por eso
      // se vuelve a la pantalla anterior, que ya lo muestra en la lista.
      if (widget.product.id == 'new') {
        // Mismo texto que al editar: los recorridos lo esperan.
        widget.onShowSnackbar('Producto actualizado');
        Navigator.of(context).maybePop();
        return;
      }
      widget.onShowSnackbar('Producto actualizado');
      return;
    }

    // `onFormSubmit` devuelve false tanto por validación como por red; el
    // mensaje original culpaba siempre a la conexión.
    final isFormValid =
        ref.read(productFormProvider(widget.product)).isFormValid;
    widget.onShowSnackbar(
      isFormValid
          ? 'No fue posible guardar el producto. Revisa tu conexión e '
              'inténtalo nuevamente.'
          : 'Revisa los campos marcados antes de guardar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 16 + bottomInset),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(top: BorderSide(color: tokens.ink, width: 2)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Align(
          child: InkHardButton(
            tokens: tokens,
            icon: _saving ? Icons.hourglass_top_rounded : Icons.check_rounded,
            label: 'Guardar producto',
            onTap: _save,
          ),
        ),
      ),
    );
  }
}
