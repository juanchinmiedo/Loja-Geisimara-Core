import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/screens/introduction/onboarding_screen.dart';
import 'package:salon_app/components/bottom_navigationbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimate = true;
  bool isClicked = false; // ahora mismo no se usa, pero lo mantengo por si luego lo necesitas

  final width = 50;

  @override
  void initState() {
    super.initState();

    // 1) Animación: después de 1 segundo, hacemos aparecer el logo
    Future.delayed(const Duration(seconds: 1), (() {
      if (!mounted) return;
      setState(() {
        isAnimate = false;
      });
    }));

    // 2) Después de 5 segundos en total, decidimos adónde ir
    Future.delayed(const Duration(seconds: 5), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Ya hay sesión iniciada → vamos directamente al home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const BottomNavigationComponent(),
        ),
      );
    } else {
      // No hay sesión → mostramos el onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnBoardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 70, vertical: 150),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedPadding(
                padding: EdgeInsets.only(top: isAnimate ? 40 : 0),
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOutCubicEmphasized,
                child: AnimatedOpacity(
                  opacity: isAnimate ? 0 : 1,
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInCubic,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Si algún día quieres poner un subtítulo o loader, lo puedes añadir aquí
            ],
          ),
        ),
      ),
    );
  }
}
