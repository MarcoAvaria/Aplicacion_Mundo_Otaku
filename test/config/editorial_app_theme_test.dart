import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la transición entre modos es gradual y suavizada', () {
    expect(
      EditorialAppTheme.transitionDuration,
      const Duration(milliseconds: 360),
    );
    expect(EditorialAppTheme.transitionCurve, Curves.easeInOutCubic);
  });

  test('los modos claro y oscuro comparten la misma tipografía', () {
    final light = EditorialAppTheme.light.textTheme;
    final dark = EditorialAppTheme.dark.textTheme;

    final lightStyles = <TextStyle?>[
      light.headlineSmall,
      light.titleLarge,
      light.titleMedium,
      light.titleSmall,
      light.bodyLarge,
      light.bodyMedium,
      light.bodySmall,
      light.labelLarge,
      light.labelMedium,
    ];
    final darkStyles = <TextStyle?>[
      dark.headlineSmall,
      dark.titleLarge,
      dark.titleMedium,
      dark.titleSmall,
      dark.bodyLarge,
      dark.bodyMedium,
      dark.bodySmall,
      dark.labelLarge,
      dark.labelMedium,
    ];

    for (var index = 0; index < lightStyles.length; index++) {
      expect(darkStyles[index]?.fontFamily, lightStyles[index]?.fontFamily);
      expect(darkStyles[index]?.fontSize, lightStyles[index]?.fontSize);
      expect(darkStyles[index]?.fontWeight, lightStyles[index]?.fontWeight);
      expect(darkStyles[index]?.height, lightStyles[index]?.height);
    }
  });
}
