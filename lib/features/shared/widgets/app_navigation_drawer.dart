import 'dart:math' as math;

import 'package:aplicacion_mundo_otaku/config/config.dart';
import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final userName = ref.watch(authProvider).user?.fullName.trim();
    final displayName = userName == null || userName.isEmpty
        ? 'Miembro de Mundo Otaku'
        : userName;
    final initial = displayName.substring(0, 1).toUpperCase();
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final width = math.min(MediaQuery.sizeOf(context).width * 0.88, 360.0);

    return Drawer(
      width: width,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.primary,
                    child: Text(
                      initial,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qué bueno verte',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _HighlightedDestination(
                label: 'Descubrir productos',
                icon: Icons.home_outlined,
                selected: currentLocation == AppRoutes.discover,
                onTap: () => _go(context, AppRoutes.discover),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'OTRAS OPCIONES',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _DrawerDestination(
                    label: 'Mis productos',
                    icon: Icons.inventory_2_outlined,
                    selected: currentLocation == AppRoutes.products,
                    onTap: () => _go(context, AppRoutes.products),
                  ),
                  _DrawerDestination(
                    label: 'Chats de intercambio',
                    icon: Icons.chat_bubble_outline_rounded,
                    selected: currentLocation == AppRoutes.chatList,
                    onTap: () => _go(context, AppRoutes.chatList),
                  ),
                  _DrawerDestination(
                    label: 'Solicitudes enviadas',
                    icon: Icons.send_outlined,
                    selected: currentLocation == AppRoutes.requestedList,
                    onTap: () => _go(context, AppRoutes.requestedList),
                  ),
                  _DrawerDestination(
                    label: 'Solicitudes recibidas',
                    icon: Icons.inbox_outlined,
                    selected: currentLocation == AppRoutes.receivedList,
                    onTap: () => _go(context, AppRoutes.receivedList),
                  ),
                  _OptionsSubmenu(ref: ref),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: ListTile(
                minLeadingWidth: 24,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Cerrar sesión'),
                textColor: colors.onSurfaceVariant,
                iconColor: colors.onSurfaceVariant,
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String location) {
    scaffoldKey.currentState?.closeDrawer();
    context.go(location);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    scaffoldKey.currentState?.closeDrawer();
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _OptionsSubmenu extends StatelessWidget {
  const _OptionsSubmenu({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedMode = ref.watch(appThemeModeProvider);
    final isDarkMode = selectedMode == ThemeMode.dark ||
        selectedMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Opciones'),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lightControl),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lightControl),
        ),
        children: [
          Material(
            color: colors.surfaceVariant.withOpacity(0.55),
            borderRadius: BorderRadius.circular(AppRadius.lightControl),
            child: SwitchListTile.adaptive(
              value: isDarkMode,
              onChanged: (enabled) =>
                  ref.read(appThemeModeProvider.notifier).setDarkMode(enabled),
              secondary: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Modo'),
              subtitle: Text(isDarkMode ? 'Oscuro' : 'Claro'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lightControl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedDestination extends StatelessWidget {
  const _HighlightedDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.lightControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lightControl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.circle : Icons.chevron_right_rounded,
                  color: colors.primary,
                  size: selected ? 8 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        minLeadingWidth: 24,
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        selected: selected,
        selectedColor: colors.primary,
        selectedTileColor: colors.primaryContainer,
        onTap: onTap,
      ),
    );
  }
}
