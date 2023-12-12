import 'package:aplicacion_mundo_otaku/features/auth/auth.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/chat_list_screen.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/received_chat_list.dart';
import 'package:aplicacion_mundo_otaku/features/chats/presentation/screens/requested_chat_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aplicacion_mundo_otaku/features/shared/shared.dart';
import 'package:go_router/go_router.dart';

class ConfigurationMenu extends ConsumerStatefulWidget {
  
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ConfigurationMenu({
    super.key,
    required this.scaffoldKey,
  });

  @override
  ConfigurationMenuState createState() => ConfigurationMenuState();
}

class ConfigurationMenuState extends ConsumerState<ConfigurationMenu> {

  int navDrawerIndex = 0;

  @override
  Widget build(BuildContext context) {

    final hasNotch = MediaQuery.of(context).viewPadding.top > 45;
    final textStyles = Theme.of(context).textTheme;

    // Obtener el usuario actual del proveedor de autenticación
    final currentUser = ref.read(authProvider);
    final currentUserName = currentUser.user?.fullName; 

    return NavigationDrawer(
      elevation: 1,
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {

        setState(() {
          navDrawerIndex = value;
        });

        // final menuItem = appMenuItems[value];
        // context.push( menuItem.link );
        widget.scaffoldKey.currentState?.closeDrawer();

      },
      children: [

        Padding(
          padding: EdgeInsets.fromLTRB(20, hasNotch ? 0 : 20, 16, 0),
          child: Text('¡Saludos!', style: textStyles.titleMedium ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
          child: Text('$currentUserName', style: textStyles.titleSmall ),
        ),

        const NavigationDrawerDestination(
            icon: Icon( Icons.home_outlined ), 
            label: Text( 'Productos' ),
        ),


        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 10, 16, 10),
          child: Text('Otras opciones'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ButtonLogin(
            onPressed: () {
              context.goNamed( ProductsScreen.name );
            },
            text: 'Mis productos'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              context.goNamed( DiscoverScreen.name );
            },
            text: '¡Descubre!'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              context.goNamed( ChatListScreen.name );
            },
            text: 'Chats de intercambio :)'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              context.goNamed( RequestedListScreen.name );
            },
            text: 'Solicitudes enviadas pendientes'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              context.goNamed( ReceivedListScreen.name );
            },
            text: 'Solicitudes recibidas'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              context.goNamed( UserListScreen.name );
            },
            text: 'Mensajeria'
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              //ref.read(authProvider.notifier).logout();
            },
            text: 'Editar perfil'
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              //context.goNamed( noti );
            },
            text: 'Notificaciones'
          ),
        ),
        */
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              
              context.goNamed( PermisosScreen.name );
            },
            text: 'Permisos'
          ),
        ),
        */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomFilledButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            text: 'Cerrar sesión'
          ),
        ),

      ]
    );
  }
}