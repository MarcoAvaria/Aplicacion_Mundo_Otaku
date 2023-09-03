import 'package:flutter/material.dart';

import '../../presentation/screens/discover/mangas_screen.dart';

class MenuItemOption {
  final String title;
  final String? subTitle;
  final String? link;
  final IconData? icon;
  void Function(BuildContext context)? customOnTap;

  MenuItemOption(
      {required this.title,
      this.subTitle,
      this.link,
      this.icon,
      this.customOnTap});
}

void customOnTap(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const MangaScreen(),
    ),
  );
  // Acción al hacer clic en "Editar Perfil"
}

List<MenuItemOption> appMenuItems = <MenuItemOption>[
  MenuItemOption(title: 'Social', subTitle: null, link: null, icon: null),
  MenuItemOption(
      title: 'Mangas',
      subTitle: '¡Ve los mangas disponibles!',
      link: 'Aquí va el link...?',
      icon: Icons.book_online_outlined),
  MenuItemOption(
      title: 'Descubre',
      subTitle: 'Descubre sorpresas cerca de ti',
      link: 'Aquí va el link...?',
      icon: Icons.airline_stops_rounded),
  MenuItemOption(
      title: 'Mensajeria',
      subTitle: 'Escribe a tus contactos',
      link: 'Aquí va el link...?',
      icon: Icons.chat),
  MenuItemOption(
      title: 'Perfil de Usuario', subTitle: null, link: null, icon: null),
  MenuItemOption(
      title: 'Editar perfil',
      subTitle: 'Configura y personaliza tus datos',
      link: 'Aquí va el link...?',
      icon: Icons.person),
  MenuItemOption(
      title: 'Cambiar contraseña',
      subTitle: 'Modifica tu contraseña',
      link: 'Aquí va el link...?',
      icon: Icons.lock),
  MenuItemOption(
      title: 'Notificaciones',
      subTitle: '¿Que mensajes emergentes quieres ver?',
      link: 'Aquí va el link...?',
      icon: Icons.notifications),
  MenuItemOption(
      title: 'Cerrar Sesión',
      subTitle: 'Recomendable si no es tu propio dispositvo',
      link: 'Aquí va el link...?',
      icon: Icons.exit_to_app),
  MenuItemOption(
      title: 'Volver',
      subTitle: '¿Que mensajes emergentes quieres ver?',
      link: 'Aquí va el link...?',
      icon: Icons.arrow_back),
];
