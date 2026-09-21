import 'dart:async';

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/domain.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/providers/providers.dart';
import 'package:aplicacion_mundo_otaku/features/products/presentation/screens/ink_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de `InkProductScreen` (T-037).
///
/// Usan el producto 'new', que `ProductNotifier` arma sin pedir nada al
/// repositorio, y un repositorio falso para el guardado.
void main() {
  late _ProductsRepository repository;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    // Alto de sobra para que el ListView construya todo el formulario.
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    repository = _ProductsRepository();
    container = ProviderContainer(
      overrides: [productsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: EditorialAppTheme.light,
          darkTheme: EditorialAppTheme.dark,
          // Las capturas del problema original eran en modo oscuro.
          themeMode: ThemeMode.dark,
          home: const InkProductScreen(productId: 'new'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Product currentProduct() => container.read(productProvider('new')).product!;

  testWidgets('muestra las tres secciones y las etiquetas corregidas',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.text('GENERALES'), findsOneWidget);
    expect(find.text('CLASIFICACIÓN'), findsOneWidget);
    expect(find.text('DESCRIPCIÓN Y ETIQUETAS'), findsOneWidget);
    // Nombres accesibles que usan los recorridos Playwright
    // (`getByLabel` busca por subcadena, igual que estas expresiones).
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Nombre')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'Volumen \| Tomo')), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'Tags \(Separados por coma\)')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp('Imágenes del producto: 0')),
      findsWidgets,
    );
    semantics.dispose();
    // Un producto nuevo no se puede borrar.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('clasificación en grilla de dos columnas, como la maqueta',
      (tester) async {
    await pumpScreen(tester);

    final demografia = find.text('Demografía');
    final tipo = find.text('Tipo');
    final genero = find.text('Género');

    // Demografía y Tipo en la misma fila, Género debajo.
    expect(tester.getTopLeft(demografia).dy, tester.getTopLeft(tipo).dy);
    expect(tester.getTopLeft(tipo).dx, greaterThan(390 / 2));
    expect(
      tester.getTopLeft(genero).dy,
      greaterThan(tester.getTopLeft(demografia).dy),
    );
    // Las opciones no se muestran hasta abrir la casilla.
    expect(find.text('Seinen'), findsNothing);
  });

  testWidgets('elegir en la hoja actualiza el formulario', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Demografía'));
    await tester.pumpAndSettle();
    // El valor guardado sigue siendo 'Komodo'; solo cambia lo que se lee.
    expect(find.text('Kodomo'), findsOneWidget);
    expect(find.text('Komodo'), findsNothing);
    await tester.tap(find.text('Seinen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tipo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manga').last);
    await tester.pumpAndSettle();

    final form = container.read(productFormProvider(currentProduct()));
    expect(form.demographic, 'Seinen');
    expect(form.typeOf, 'Manga');
    // La casilla muestra la nueva elección.
    expect(find.text('Seinen'), findsOneWidget);
  });

  testWidgets('sin nombre avisa que faltan campos, no que falla la conexión',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Guardar producto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Revisa los campos marcados antes de guardar.'),
      findsOneWidget,
    );
    expect(repository.savedPayloads, isEmpty);
  });

  testWidgets('un doble toque en guardar envía el formulario una sola vez',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Hajime no Ippo 01');
    await tester.pump();

    await tester.tap(find.text('Guardar producto'));
    await tester.pump();
    // Mientras guarda, el ícono cambia pero el nombre del botón no (ancla de
    // los recorridos Playwright).
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    await tester.tap(find.text('Guardar producto'));
    await tester.pump();

    expect(repository.savedPayloads, hasLength(1));
    expect(repository.savedPayloads.single['title'], 'Hajime no Ippo 01');
    expect(repository.savedPayloads.single['id'], isNull);

    repository.pendingSave!.complete(_product('creado-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Producto actualizado'), findsOneWidget);
  });
}

Product _product(String id) => Product(
      id: id,
      title: 'Producto $id',
      typeOf: 'Manga',
      description: '',
      tomo: 1,
      sizeOf: 'Ninguno',
      gender: 'Ninguno',
      demographic: 'Shonen',
      tags: const [],
      images: const [],
    );

class _ProductsRepository implements ProductsRepository {
  final savedPayloads = <Map<String, dynamic>>[];
  Completer<Product>? pendingSave;

  @override
  Future<List<Product>> getProductsByPage(
          {int limit = 10, int offset = 0}) async =>
      [];

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) {
    savedPayloads.add(productLike);
    pendingSave = Completer<Product>();
    return pendingSave!.future;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fuera del alcance de esta prueba');
}
