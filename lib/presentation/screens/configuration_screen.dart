import 'package:flutter/material.dart';

import 'mangas_screen.dart';

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
            const Text(
              'Perfil de Usuario',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar Perfil'),
              onTap: () {
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
