import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';
//import 'package:go_router/go_router.dart';

//import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/screens.dart';


class CustomAppBar {
  static AppBar customAppBar(BuildContext context, String title ) {

    return AppBar(
      title: Text( title ),
      actions: [
        IconButton(
          onPressed: (){}, 
          icon: const Icon( Icons.search_rounded)
        )
      ],
    );
  }
}

/*class CustomAppBar {
  static AppBar myOwnMethodAppBar(BuildContext context, String title) {

    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.grey.shade400,
      centerTitle: true,
      title: Text(title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      actions: [
        InkWell(
          onTap: () {
            /*Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const ConfigurationScreen()),
              (route) => false,
            );*/
            //context.pushNamed( ConfigurationScreen.name );
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
} */