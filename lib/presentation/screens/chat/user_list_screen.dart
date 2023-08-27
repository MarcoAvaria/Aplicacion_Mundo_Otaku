import 'package:aplicacion_mundo_otaku/presentation/screens/chat/chat_screen.dart';
//import 'package:aplicacion_mundo_otaku/presentation/screens/configuration_screen.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/custom_appbar.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      /*
      appBar: AppBar(
        title: const Text('Mensajes | Contactos'),
      ),
      */
      appBar: CustomAppBar.myOwnMethodAppBar(context, 'Mensajes | Contactos'),

      
      body: ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];
          return ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(user.profileImage)),
            title: Text(user.username),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(user: user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class User {
  final String username;
  final String profileImage;

  User({
    required this.username,
    required this.profileImage,
  });
}

final List<User> userList = [
  User(username: 'Han Yoo Hyun', profileImage: 'https://vietotaku.com/wp-content/uploads/2021/11/cot-truyen-manhwa-real-man.jpg'),
  User(username: 'Bell Cranel', profileImage: 'https://cdn.myanimelist.net/images/characters/15/508889.jpg'),
  // Add more users here
];
