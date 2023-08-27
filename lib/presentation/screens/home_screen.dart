import 'package:aplicacion_mundo_otaku/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    //var d = const Duration(seconds: 4);
    Future.delayed( const Duration( seconds: 4), () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return const Scaffold(
      body: Center(
        child: Text("Esto es Mundo Otaku", style: TextStyle(fontSize: 15),))
    );
  } 
}