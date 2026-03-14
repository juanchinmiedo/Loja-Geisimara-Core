// lib/screens/introduction/spalsh_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/screens/introduction/onboarding_screen.dart';
import 'package:salon_app/components/bottom_navigationbar.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimate = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => isAnimate = false);
    });
    Future.delayed(const Duration(seconds: 5), _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnBoardingScreen()));
      return;
    }

    final userProvider = context.read<UserProvider>();
    userProvider.setUser(currentUser);

    // Retry por si los claims tardan en propagarse al reiniciar la app
    await userProvider.refreshSessionWithRetry();

    if (!mounted) return;

    if (!userProvider.isAuthorized) {
      // Claims revocados mientras la app estaba cerrada
      await FirebaseAuth.instance.signOut();
      userProvider.setUser(null);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnBoardingScreen()));
      return;
    }

    context.read<AdminNavProvider>().setTab(0);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const BottomNavigationComponent()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 150),
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
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
