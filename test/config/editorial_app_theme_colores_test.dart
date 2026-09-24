// Fija los valores del tema que Flutter puede mover **sin que nada falle**.
//
// Existe por un caso real: al pasar de Flutter 3.16.8 a 3.47.5, el
// `canvasColor` de los dos modos cambió solo. Hasta la 3.16 ese valor salía por
// omisión de `ColorScheme.background`; ese campo se retiró del `ColorScheme`, y
// desde entonces sale de `surface`. El fondo del lienzo pasó de #FDF9FC a
// blanco en claro y de #131117 a #1B1820 en oscuro, y **no falló una sola
// prueba, ni el análisis, ni la compilación**: el color simplemente se aclaró.
//
// El archivo `editorial_app_theme_test.dart` sigue intacto y cubre otra cosa
// —la transición entre modos y la tipografía compartida—. Este se concentra en
// los colores, que es la parte que deriva en silencio.
//
// Si una de estas pruebas falla después de actualizar Flutter, no es
// necesariamente un error: puede ser un cambio legítimo del marco. Lo que la
// prueba garantiza es que **nadie se entere tarde**.
import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La paleta de marca. `PRECAUCIONES.md` pide conservarla, así que va fijada.
const _fondoClaro = Color(0xFFFDF9FC);
const _superficieClara = Color(0xFFFFFFFF);
const _magentaClaro = Color(0xFF9A1E74);

const _fondoOscuro = Color(0xFF131117);
const _superficieOscura = Color(0xFF1B1820);
const _magentaNeon = Color(0xFFFF3FA0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('el lienzo sigue al fondo de la aplicación, no a la superficie', () {
    // Esta es **la** prueba del caso real. `canvasColor` es el color que usan
    // `Material` de tipo lienzo y los menús desplegables. Si sigue a `surface`
    // en vez de al fondo, esos elementos se aclaran de golpe en modo claro y se
    // aclaran también en oscuro, sin que nada avise.
    test('en modo claro', () {
      final tema = EditorialAppTheme.light;
      expect(tema.canvasColor, tema.scaffoldBackgroundColor);
      expect(tema.canvasColor, _fondoClaro);
      expect(
        tema.canvasColor,
        isNot(tema.colorScheme.surface),
        reason: 'si el lienzo toma el color de la superficie, es que volvió al '
            'valor por omisión de Flutter y se perdió el fondo de la marca',
      );
    });

    test('en modo oscuro', () {
      final tema = EditorialAppTheme.dark;
      expect(tema.canvasColor, tema.scaffoldBackgroundColor);
      expect(tema.canvasColor, _fondoOscuro);
      expect(tema.canvasColor, isNot(tema.colorScheme.surface));
    });
  });

  group('la paleta de marca está donde corresponde', () {
    test('modo claro', () {
      final tema = EditorialAppTheme.light;
      expect(tema.brightness, Brightness.light);
      expect(tema.colorScheme.brightness, Brightness.light);
      expect(tema.colorScheme.primary, _magentaClaro);
      expect(tema.colorScheme.surface, _superficieClara);
      expect(tema.scaffoldBackgroundColor, _fondoClaro);
      expect(tema.colorScheme.onPrimary, Colors.white);
    });

    test('modo oscuro', () {
      final tema = EditorialAppTheme.dark;
      expect(tema.brightness, Brightness.dark);
      expect(tema.colorScheme.brightness, Brightness.dark);
      expect(tema.colorScheme.primary, _magentaNeon);
      expect(tema.colorScheme.surface, _superficieOscura);
      expect(tema.scaffoldBackgroundColor, _fondoOscuro);
      // En oscuro el texto sobre el magenta es la superficie, no blanco: el
      // neón es demasiado claro para llevar texto blanco encima.
      expect(tema.colorScheme.onPrimary, _superficieOscura);
    });

    test('el fondo y la superficie son colores distintos en ambos modos', () {
      // Es lo que da la sensación de tarjeta levantada sobre el fondo. Si
      // alguna vez coinciden, la jerarquía visual desaparece.
      for (final tema in [EditorialAppTheme.light, EditorialAppTheme.dark]) {
        expect(tema.scaffoldBackgroundColor, isNot(tema.colorScheme.surface));
      }
    });
  });

  group('las superficies grandes no llevan el tinte de Material 3', () {
    // El rediseño dibuja superficies planas con un borde. El tinte de M3 las
    // teñiría de magenta según la elevación, que es justo lo que
    // `PRECAUCIONES.md` prohíbe: el neón solo va en acentos pequeños.
    test('ni el esquema ni los componentes tiñen', () {
      for (final tema in [EditorialAppTheme.light, EditorialAppTheme.dark]) {
        expect(tema.useMaterial3, isTrue);
        expect(tema.colorScheme.surfaceTint, Colors.transparent);
        expect(tema.appBarTheme.surfaceTintColor, Colors.transparent);
        expect(tema.cardTheme.surfaceTintColor, Colors.transparent);
      }
    });

    test('la barra superior y las tarjetas son la superficie, sin elevación',
        () {
      for (final tema in [EditorialAppTheme.light, EditorialAppTheme.dark]) {
        expect(tema.appBarTheme.backgroundColor, tema.colorScheme.surface);
        expect(tema.appBarTheme.foregroundColor, tema.colorScheme.onSurface);
        expect(tema.appBarTheme.elevation, 0);
        expect(tema.appBarTheme.scrolledUnderElevation, 0);
        expect(tema.cardTheme.color, tema.colorScheme.surface);
        expect(tema.cardTheme.elevation, 0);
      }
    });
  });

  test('el separador usa el mismo trazo que los bordes del esquema', () {
    // Si el separador se desviara del `outline`, las tarjetas y las líneas
    // divisorias dejarían de verse como parte del mismo sistema.
    for (final tema in [EditorialAppTheme.light, EditorialAppTheme.dark]) {
      expect(tema.dividerTheme.color, tema.colorScheme.outline);
      expect(tema.dividerTheme.thickness, 1);
      expect(tema.dividerTheme.space, 1);
    }
  });

  test('el menú lateral usa la superficie en claro y un tono propio en oscuro',
      () {
    // En claro el menú es la superficie, como las tarjetas. En oscuro lleva un
    // color propio, #17151B, deliberadamente **entre** el fondo (#131117) y la
    // superficie (#1B1820): así se despega del fondo sin llegar a parecer una
    // tarjeta flotando. No es un descuido, y por eso queda fijado.
    expect(
      EditorialAppTheme.light.drawerTheme.backgroundColor,
      EditorialAppTheme.light.colorScheme.surface,
    );

    final menuOscuro = EditorialAppTheme.dark.drawerTheme.backgroundColor!;
    expect(menuOscuro, const Color(0xFF17151B));
    expect(menuOscuro.r, greaterThan(_fondoOscuro.r));
    expect(menuOscuro.r, lessThan(_superficieOscura.r));

    for (final tema in [EditorialAppTheme.light, EditorialAppTheme.dark]) {
      expect(tema.drawerTheme.surfaceTintColor, Colors.transparent);
      expect(tema.drawerTheme.scrimColor, tema.colorScheme.scrim);
    }
  });

  test('los dos modos comparten estructura de color, solo cambia la paleta',
      () {
    // Una red contra el error de tocar un modo y olvidar el otro.
    final claro = EditorialAppTheme.light.colorScheme;
    final oscuro = EditorialAppTheme.dark.colorScheme;

    // Las relaciones internas del esquema son las mismas en ambos.
    for (final esquema in [claro, oscuro]) {
      expect(esquema.secondary, esquema.primary);
      expect(esquema.tertiary, esquema.primary);
      expect(esquema.onPrimaryContainer, esquema.primary);
      expect(esquema.outlineVariant, esquema.outline);
      expect(esquema.inversePrimary, esquema.primary);
    }

    // Y ningún color se repite entre modos, porque son paletas distintas.
    expect(claro.primary, isNot(oscuro.primary));
    expect(claro.surface, isNot(oscuro.surface));
    expect(claro.onSurface, isNot(oscuro.onSurface));
  });
}
