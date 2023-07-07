import 'package:flutter/material.dart';

import 'mangas_screen.dart';

class ConfigurationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
              leading: Icon(Icons.person),
              title: Text('Editar Perfil'),
              onTap: () {
                // Acción al hacer clic en "Editar Perfil"
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Cambiar Contraseña'),
              onTap: () {
                // Acción al hacer clic en "Cambiar Contraseña"
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notificaciones'),
              onTap: () {
                // Acción al hacer clic en "Notificaciones"
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Cerrar Sesión'),
              onTap: () {
                // Acción al hacer clic en "Cerrar Sesión"
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_back),
              title: Text('Volver'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MangaScreen()),
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
