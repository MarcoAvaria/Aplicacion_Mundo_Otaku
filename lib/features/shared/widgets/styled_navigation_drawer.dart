import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ink_navigation_drawer.dart';
import 'webtoon_navigation_drawer.dart';

/// Menú lateral de la propuesta "Tinta y Neón".
///
/// Delega en la variante que el usuario haya elegido. El menú original
/// (`AppNavigationDrawer`) se conserva intacto para poder volver a él.
class StyledNavigationDrawer extends ConsumerWidget {
  const StyledNavigationDrawer({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (ref.watch(drawerStyleProvider)) {
      case DrawerStyle.capitulos:
        return InkNavigationDrawer(scaffoldKey: scaffoldKey);
      case DrawerStyle.webtoon:
        return WebtoonNavigationDrawer(scaffoldKey: scaffoldKey);
    }
  }
}

@immutable
class DrawerDestination {
  const DrawerDestination({
    required this.number,
    required this.label,
    required this.caption,
    required this.location,
  });

  final String number;
  final String label;
  final String caption;
  final String location;
}

const drawerDestinations = <DrawerDestination>[
  DrawerDestination(
    number: '01',
    label: 'Descubrir',
    caption: 'Lo que publican otras personas',
    location: AppRoutes.discover,
  ),
  DrawerDestination(
    number: '02',
    label: 'Mi estante',
    caption: 'Los productos que tienes publicados',
    location: AppRoutes.products,
  ),
  DrawerDestination(
    number: '03',
    label: 'Chats',
    caption: 'Conversaciones de intercambio',
    location: AppRoutes.chatList,
  ),
  DrawerDestination(
    number: '04',
    label: 'Enviadas',
    caption: 'Propuestas que hiciste tú',
    location: AppRoutes.requestedList,
  ),
  DrawerDestination(
    number: '05',
    label: 'Recibidas',
    caption: 'Propuestas que te hicieron',
    location: AppRoutes.receivedList,
  ),
];

/// Acciones que las dos variantes comparten.
extension DrawerActions on GlobalKey<ScaffoldState> {
  void goTo(BuildContext context, String location) {
    currentState?.closeDrawer();
    context.go(location);
  }

  Future<void> logout(BuildContext context, WidgetRef ref) async {
    currentState?.closeDrawer();
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

/// Nombre a mostrar en la cabecera del menú.
String drawerDisplayName(WidgetRef ref) {
  final userName = ref.watch(authProvider).user?.fullName.trim();
  return userName == null || userName.isEmpty
      ? 'Miembro de Mundo Otaku'
      : userName;
}

bool drawerIsDarkMode(BuildContext context, WidgetRef ref) {
  final selectedMode = ref.watch(appThemeModeProvider);
  return selectedMode == ThemeMode.dark ||
      selectedMode == ThemeMode.system &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark;
}
