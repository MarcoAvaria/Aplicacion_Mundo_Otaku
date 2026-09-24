import 'dart:math' as math;

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'styled_navigation_drawer.dart';

/// Menú "Hilo webtoon": los destinos bajan encadenados por una línea vertical,
/// como el scroll continuo de un manhwa.
class WebtoonNavigationDrawer extends ConsumerWidget {
  const WebtoonNavigationDrawer({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = _ThreadTokens.of(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.86, 340.0);

    return Drawer(
      width: width,
      backgroundColor: tokens.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(tokens: tokens, name: drawerDisplayName(ref)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
                itemCount: drawerDestinations.length,
                itemBuilder: (context, index) {
                  final destination = drawerDestinations[index];
                  return _ThreadTile(
                    tokens: tokens,
                    destination: destination,
                    selected: currentLocation == destination.location,
                    isLast: index == drawerDestinations.length - 1,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tokens, required this.name});

  final _ThreadTokens tokens;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUÉ BUENO VERTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.7,
              color: tokens.muted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.displayStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: tokens.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 54, height: 2, color: tokens.accent),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.tokens,
    required this.destination,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  final _ThreadTokens tokens;
  final DrawerDestination destination;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 6,
          top: 0,
          bottom: isLast ? null : 0,
          height: isLast ? 16 : null,
          width: 2,
          child: ColoredBox(color: tokens.thread),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: _Node(tokens: tokens, selected: selected),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.label,
                          style: AppFonts.displayStyle(
                            fontSize: selected ? 25 : 23,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w700,
                            height: 1.05,
                            color: selected ? tokens.accent : tokens.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          destination.caption,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: tokens.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.tokens, required this.selected});

  final _ThreadTokens tokens;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tokens.accent : tokens.surface,
        border: selected
            ? null
            : Border.all(color: tokens.accent, width: 2.5),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.18),
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.tokens, required this.scaffoldKey});

  final _ThreadTokens tokens;
  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = drawerIsDarkMode(context, ref);
    final style = ref.watch(drawerStyleProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 20, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El nombre y el interruptor tienen que llegar como **un solo nodo**
          // al lector de pantalla. Sin esto, el interruptor viaja sin nombre y
          // la palabra "Modo oscuro", al no tener acción propia, se va al nodo
          // grande de la ruta del menú: se anuncia el estado, pero nunca de qué.
          MergeSemantics(
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
                  activeThumbColor: tokens.accent,
                  onChanged: (enabled) => ref
                      .read(appThemeModeProvider.notifier)
                      .setDarkMode(enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ESTILO DEL MENÚ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: tokens.muted,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 12),
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

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.tokens,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _ThreadTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.accentWash : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected ? tokens.accent : tokens.divider,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? tokens.accent : tokens.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadTokens {
  const _ThreadTokens({
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentWash,
    required this.divider,
    required this.thread,
  });

  final Color surface;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentWash;
  final Color divider;
  final Color thread;

  factory _ThreadTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return _ThreadTokens(
        surface: const Color(0xFF17151B),
        text: const Color(0xFFF1EEF5),
        muted: const Color(0xFF9089A0),
        accent: const Color(0xFFFF3FA0),
        accentWash: const Color(0xFFFF3FA0).withValues(alpha: 0.10),
        divider: const Color(0xFF2C2833),
        thread: const Color(0xFFFF3FA0).withValues(alpha: 0.45),
      );
    }

    return _ThreadTokens(
      surface: const Color(0xFFFFFFFF),
      text: const Color(0xFF241626),
      muted: const Color(0xFF6E5F6C),
      accent: const Color(0xFF9A1E74),
      accentWash: const Color(0xFF9A1E74).withValues(alpha: 0.08),
      divider: const Color(0xFFECE1EA),
      thread: const Color(0xFF9A1E74).withValues(alpha: 0.35),
    );
  }
}
