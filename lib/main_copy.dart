import 'package:aplicacion_mundo_otaku/presentation/screens/mangas_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  //const MyApp({ Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
       
        /*colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,*/ // ESTO ESTABA AL PRINCIPIO
        //primarySwatch: Colors.blue, 
      ),
      home: const MangaScreen(),
    );
  }
}