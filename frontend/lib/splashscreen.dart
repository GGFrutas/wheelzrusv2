import 'package:flutter/material.dart';
import 'package:frontend/screen/login_screen.dart';
import 'package:lottie/lottie.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  _SplashscreenState createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    // Delay navigation to the login screen after the splash screen animation
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
          // builder: (context) => LocationScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d3c34),
      body: Center(
        child: Lottie.asset('assets/animation/Animation - 1726470320949.json'),
      ),
    );
  }
}
