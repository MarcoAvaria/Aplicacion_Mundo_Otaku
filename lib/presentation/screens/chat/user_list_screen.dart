import 'package:aplicacion_mundo_otaku/presentation/screens/chat/chat_screen.dart';
import 'package:aplicacion_mundo_otaku/presentation/screens/configuration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

      appBar: newMethodAppBar(context),
      
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

  AppBar newMethodAppBar(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.grey.shade400,
      centerTitle: true,
      title: const Text('Mensajes | Contactos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      actions: [
        InkWell(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const ConfigurationScreen()),
              (route) => false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset("assets/anime_and_manga.svg", width: 30.0),
          ),
        ),
        const SizedBox(width: 15.0),
      ],
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
