import 'package:flutter/material.dart';

class MenuItemOption {
  final String title;
  final String? subTitle;
  final String? link;
  final IconData? icon;

  const MenuItemOption({
    required this.title,
    this.subTitle,
    this.link,
    this.icon,
  });
}

const appMenuItems = <MenuItemOption>[
  MenuItemOption(
      title: 'Social',
      subTitle: null,
      link: null,
      icon: null),
  MenuItemOption(
      title: 'Mangas',
      subTitle: '¡Ve los mangas disponibles!',
      link: 'Aquí va el link...?holi',
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
      title: 'Perf',
      subTitle: null,
      link: null,
      icon: null),
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
