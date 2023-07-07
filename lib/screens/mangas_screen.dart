import 'package:aplicacion_mundo_otaku/models/objetos_modelos.dart';
import 'package:aplicacion_mundo_otaku/screens/configuration_screen.dart';
import 'package:aplicacion_mundo_otaku/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MangaScreen extends StatefulWidget {
  //const MangaScreen({super.key}); // ASÍ ESTABA
  const MangaScreen({Key? key}) : super(key: key); // ASÍ LO ESTOY PROBANDO

  @override
  State<MangaScreen> createState() => _MangaScreenState();
}

class _MangaScreenState extends State<MangaScreen> {
  List<String> menus = [
    "Todos",
    "Menú 1",
    "Menú 2",
    "Menú 3",
    "Menú 4",
    "Menú 5",
    "Menú 6"
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.grey.shade200,
        centerTitle: true,
        title: const Text('Mangas',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ConfigurationScreen()),
                (route) => false,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  SvgPicture.asset("assets/anime_and_manga.svg", width: 30.0),
            ),
          ),
          const SizedBox(width: 15.0),
        ],
      ),

      /*
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.grey.shade200,
        centerTitle: true,
        title: const Text('Mangas',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          SvgPicture.asset("assets/anime_and_manga.svg", width: 30.0),
          const SizedBox(width: 15.0),
        ],
      ),
      */
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20.0),
            width: double.infinity,
            height: 40.0,
            //color: Colors.yellow,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              //shrinkWrap: true,
              itemCount: menus.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100.0,
                  margin: const EdgeInsets.only(left: 15.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.deepPurple[400],
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Text(
                    menus[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          Expanded(
              child: Container(
            margin: const EdgeInsets.only(left: 15.0, right: 15.0, top: 20.0),
            width: double.infinity,
            //color: Colors.yellow,
            child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    crossAxisSpacing: 15.0,
                    mainAxisSpacing: 15.0),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(120.0)),
                    // child: Image.network(src) // EN CASO DE QUERER TRAER ALGÚN RECURSO DE INTERNET

                    /*
                    child: Column(
                      children: [
                        Image.asset(products[index].path??""),
                        SizedBox(height: 10.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "${products[index].franquicia}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
                            ),

                            const SizedBox(width: 4.0),
                            Text(
                              "${products[index].precio.toString()} CLP",
                              style: TextStyle(fontSize: 20.0,),
                            ),
                          ],
                        ),
                      ],
                    ),// Los signos ??"" es en caso de index=null
                    */
                    child: Column(
                      children: [
                        Image.asset(products[index].path ?? ""),
                        //const SizedBox(height: 30.0),
                        Column(
                          children: [
                            Text(
                              "${products[index].franquicia}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25.0),
                            ),
                            Text(
                              "${products[index].precio.toString()} CLP",
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ],
                        ),
                      ],
                    ),

                    //color: Colors.orange,
                  );
                }),
          )),
        ],
      ),
    );
    //return const Placeholder(); // ASÍ ESTABA
    //return Container(); // ASÍ LO ESTOY PROBANDO
  }
}
