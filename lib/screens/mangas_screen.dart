import 'package:flutter/material.dart';

class MangaScreen extends StatefulWidget {
  //const MangaScreen({super.key}); // ASÍ ESTABA
  const MangaScreen({ Key? key }) : super(key: key); // ASÍ LO ESTOY PROBANDO

  @override
  State<MangaScreen> createState() => _MangaScreenState();
}

class _MangaScreenState extends State<MangaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
    );
    //return const Placeholder(); // ASÍ ESTABA
    //return Container(); // ASÍ LO ESTOY PROBANDO
  }
}