import 'package:aplicacion_mundo_otaku/config/menu/menu_item_options_alternative.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/chat/user_list_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/discover/discover_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/home/login_screen.dart';
import 'package:flutter/material.dart';

import '../discover/mangas_screen.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: const _ConfigurationView(),
    );
  }
}

class _ConfigurationView extends StatelessWidget {
  const _ConfigurationView();

  @override
  Widget build(BuildContext context){

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: appMenuItems.length,
      itemBuilder: (context, index) {
        final menuItem = appMenuItems[index];

        return _CustomListTile(menuItem: menuItem);
      }
    );
  }

}

class _CustomListTile extends StatelessWidget {
  const _CustomListTile({
    required this.menuItem,
  });

  final MenuItemOption menuItem;

  @override
  Widget build(BuildContext context) {

    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: (menuItem.icon == null ? null : Icon(
        menuItem.icon as IconData, color: colors.primary,)),
      title: Text(menuItem.title),
      subtitle: (menuItem.subTitle == null ? null : Text( (menuItem.subTitle as String) ) ),
      

    );
  }
}
