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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   'Social',
            //   style: TextStyle(
            //     fontSize: 20.0,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Social',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold))
            ),
            //const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.book_online_outlined),
              title: const Text('Mangas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MangaScreen(),
                  ),
                );
                // Acción al hacer clic en "Editar Perfil"
              },
            ),
            ListTile(
              leading: const Icon(Icons.airline_stops_rounded),
              title: const Text('Descubre'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiscoverScreen(),
                  ),
                );
                // Acción al hacer clic en "Editar Perfil"
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Mensajeria'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserListScreen(),
                  ),
                );
                // Acción al hacer clic en "Editar Perfil"
              },
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Perfil de Usuario',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold))
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MangaScreen(),
                  ),
                );
                // Acción al hacer clic en "Editar Perfil"
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                // Acción al hacer clic en "Cambiar Contraseña"
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificaciones'),
              onTap: () {
                // Acción al hacer clic en "Notificaciones"
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
                // Acción al hacer clic en "Cerrar Sesión"
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Volver'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MangaScreen()),
                  (route) => false,
                );
                // Acción al hacer clic en "Cerrar Sesión"
              },
            ),
          ],
        ),
      ),
    );
  }
}
