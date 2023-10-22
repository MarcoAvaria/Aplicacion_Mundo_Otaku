import 'package:aplicacion_mundo_otaku/features/shared/widgets/widgets.dart';
import 'package:aplicacion_mundo_otaku/features/products/domain/entities/product_final.dart';
import 'package:flutter/material.dart';

class MangaScreen extends StatefulWidget {
  static const String name = 'mangas_screen';
  const MangaScreen({super.key}); // ASÍ ESTABA
  //const MangaScreen({Key? key}) : super(key: key); // ASÍ LO ESTOY PROBANDO

  @override
  State<MangaScreen> createState() => _MangaScreenState();
}

const List<String> _menus = [
  "Toditos",
  "Mangas",
  "Figuras",
  "Shonen",
  "Shojo",
  "Seinen",
  "Josei"
];

class _MangaScreenState extends State<MangaScreen> {
  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: ConfigurationMenu( scaffoldKey: scaffoldKey ),
      appBar: CustomAppBar.myOwnMethodAppBar(context, 'Mangas'),

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
              itemCount: _menus.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100.0,
                  margin: const EdgeInsets.only(left: 15.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20.0)),
                  child: Text(
                    _menus[index],
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
                        borderRadius: BorderRadius.circular(300.0)),
                    // child: Image.network(src) // EN CASO DE QUERER TRAER ALGÚN RECURSO DE INTERNET

                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Image.asset(products[index].path ?? ""),
                          //const SizedBox(height: 30.0),
                          Column(
                            children: [
                              Text(
                                "${products[index].franquicia}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25.0),
                              ),
                              Text(
                                "${products[index].precio.toString()} CLP",
                                style: const TextStyle(fontSize: 20.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          )),
        ],
      ),
    );
  }
}
