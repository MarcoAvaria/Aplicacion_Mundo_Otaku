import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  static const String name = 'splash_screen';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          ContainerBackground(),
          SplashScreenPositioned(),
        ],
      ),
    );
  }
}

class ContainerBackground extends StatelessWidget {
  const ContainerBackground({
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

class SplashScreenPositioned extends StatelessWidget {
  const SplashScreenPositioned({
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
