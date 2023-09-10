import 'package:aplicacion_mundo_otaku/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  
  static const String name = 'splash_screen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    //var d = const Duration(seconds: 3);
    Future.delayed( const Duration (seconds: 3) , () {
      /*Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false);*/
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const HomeScreen()),
      );
      //context.go(location )
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          NewWidgetContainer(),
          NewWidgetPositioned(),
        ],
      ),
    );
    
  }
}

class NewWidgetContainer extends StatelessWidget {
  const NewWidgetContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/degradado_morado.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/image_icon_app.png"),
          ),
        ],
      ),
    );
  }
}

class NewWidgetPositioned extends StatelessWidget {
  const NewWidgetPositioned({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      bottom: 1,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.all(55),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 128, 4, 4),
          ),
        ),
      ),
    );
  }
}
