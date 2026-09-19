import 'dart:math' as math;

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'halftone_painter.dart';
import 'styled_navigation_drawer.dart';

/// Menú "Capítulos": cada destino es una viñeta con borde de tinta, numerada
/// como un capítulo de un tomo.
class InkNavigationDrawer extends ConsumerWidget {
  const InkNavigationDrawer({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Inclinaciones fijas por posición: cada viñeta se desalinea apenas para
  /// romper la cuadrícula sin que el texto pierda legibilidad.
  static const _tilts = <double>[-0.8, 0.4, -0.4, 0.6, -0.5];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = _InkTokens.of(context, ref);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.86, 346.0);

    return Drawer(
      width: width,
      backgroundColor: tokens.paper,
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: tokens.border, width: 3),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(tokens: tokens, name: drawerDisplayName(ref)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: drawerDestinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 11),
                  itemBuilder: (context, index) {
                    final destination = drawerDestinations[index];
                    return _ChapterTile(
                      tokens: tokens,
                      destination: destination,
                      tiltDegrees: _tilts[index % _tilts.length],
                      selected: currentLocation == destination.location,
                      onTap: () =>
                          scaffoldKey.goTo(context, destination.location),
                    );
                  },
                ),
              ),
              _Footer(tokens: tokens, scaffoldKey: scaffoldKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tokens, required this.name});

  final _InkTokens tokens;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border(bottom: BorderSide(color: tokens.border, width: 2.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: tokens.accentWash,
              border: Border.all(color: tokens.border, width: 2.5),
            ),
            child: CustomPaint(
              painter: HalftonePainter(color: tokens.accent),
              child: Center(
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: AppFonts.displayStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tokens.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUÉ BUENO VERTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.displayStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: tokens.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.tokens,
    required this.destination,
    required this.tiltDegrees,
    required this.selected,
    required this.onTap,
  });

  final _InkTokens tokens;
  final DrawerDestination destination;
  final double tiltDegrees;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? tokens.activeBackground : tokens.panel;
    final foreground = selected ? tokens.activeForeground : tokens.text;

    return Transform.rotate(
      angle: tiltDegrees * math.pi / 180,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: selected ? tokens.activeBorder : tokens.border,
            width: tokens.borderWidth,
          ),
          boxShadow: selected
              ? [BoxShadow(color: tokens.shadow, offset: const Offset(4, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Text(
                      destination.number,
                      style: AppFonts.displayStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: selected
                            ? foreground.withOpacity(0.75)
                            : tokens.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        style: AppFonts.displayStyle(
                          fontSize: 18,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.swap_horiz_rounded,
                          size: 18, color: foreground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.tokens, required this.scaffoldKey});

  final _InkTokens tokens;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = drawerIsDarkMode(context, ref);
    final style = ref.watch(drawerStyleProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InkRow(
            tokens: tokens,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Modo oscuro',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.text,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: isDark,
                  activeColor: tokens.accent,
                  onChanged: (enabled) => ref
                      .read(appThemeModeProvider.notifier)
                      .setDarkMode(enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _InkRow(
            tokens: tokens,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTILO DEL MENÚ',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _StyleOption(
                        tokens: tokens,
                        label: 'Capítulos',
                        selected: style == DrawerStyle.capitulos,
                        onTap: () => ref
                            .read(drawerStyleProvider.notifier)
                            .setStyle(DrawerStyle.capitulos),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StyleOption(
                        tokens: tokens,
                        label: 'Webtoon',
                        selected: style == DrawerStyle.webtoon,
                        onTap: () => ref
                            .read(drawerStyleProvider.notifier)
                            .setStyle(DrawerStyle.webtoon),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => scaffoldKey.logout(context, ref),
            icon: Icon(Icons.logout_rounded, size: 18, color: tokens.muted),
            label: Text(
              'Cerrar sesión',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.muted,
              ),
            ),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkRow extends StatelessWidget {
  const _InkRow({required this.tokens, required this.child});

  final _InkTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.panel,
        border: Border.all(color: tokens.border, width: tokens.borderWidth),
      ),
      child: child,
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _InkTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.activeBackground : tokens.paper,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? tokens.activeBorder : tokens.border,
                width: 2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? tokens.activeForeground : tokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colores del menú de tinta en cada modo.
///
/// En oscuro el neón nunca rellena superficies grandes: el destino activo usa
/// el contenedor magenta del tema y deja el neón para el borde y el texto.
class _InkTokens {
  const _InkTokens({
    required this.paper,
    required this.panel,
    required this.border,
    required this.borderWidth,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentWash,
    required this.activeBackground,
    required this.activeBorder,
    required this.activeForeground,
    required this.shadow,
  });

  final Color paper;
  final Color panel;
  final Color border;
  final double borderWidth;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentWash;
  final Color activeBackground;
  final Color activeBorder;
  final Color activeForeground;
  final Color shadow;

  factory _InkTokens.of(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const _InkTokens(
        paper: Color(0xFF131117),
        panel: Color(0xFF1B1820),
        border: Color(0xFF2C2833),
        borderWidth: 1.8,
        text: Color(0xFFF1EEF5),
        muted: Color(0xFF9089A0),
        accent: Color(0xFFFF3FA0),
        accentWash: Color(0xFF221C29),
        activeBackground: Color(0xFF38182D),
        activeBorder: Color(0xFFFF3FA0),
        activeForeground: Color(0xFFFF3FA0),
        shadow: Color(0xFF000000),
      );
    }

    return const _InkTokens(
      paper: Color(0xFFFDF9FC),
      panel: Color(0xFFFFFFFF),
      border: Color(0xFF241626),
      borderWidth: 2.5,
      text: Color(0xFF241626),
      muted: Color(0xFF6E5F6C),
      accent: Color(0xFF9A1E74),
      accentWash: Color(0xFFF6EAF2),
      activeBackground: Color(0xFF9A1E74),
      activeBorder: Color(0xFF241626),
      activeForeground: Color(0xFFFFFFFF),
      shadow: Color(0xFF241626),
    );
  }
}
