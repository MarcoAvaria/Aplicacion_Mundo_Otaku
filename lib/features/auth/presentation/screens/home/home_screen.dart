import 'package:aplicacion_mundo_otaku/features/auth/presentation/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {

  static const String name = 'home_screen';

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
      /*Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );*/
      context.goNamed( LoginScreen.name );
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