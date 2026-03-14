// lib/screens/introduction/onboarding_screen.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/components/bottom_navigationbar.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/controller/auth_controller.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  static const int _kLoopBase = 1000;

  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;
  bool _authLoading = false;
  bool _accessDenied = false;

  final List<String> imgAssets = [
    'assets/onBoarding_1.jpg',
    'assets/onBoarding_2.jpg',
    'assets/onBoarding_2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    final int startPage =
        _kLoopBase * (imgAssets.isEmpty ? 1 : imgAssets.length);
    _pageController =
        PageController(initialPage: startPage, viewportFraction: 1.0);
    _currentIndex = startPage % imgAssets.length;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_authLoading) return;
    setState(() {
      _authLoading = true;
      _accessDenied = false;
    });

    try {
      // 1) Firebase Auth
      final user = await Authentication.signInWithGoogle(context: context);
      if (user == null) return;

      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.setUser(user);

      // 2) Carga claims con retry (resuelve delay de propagación de Firebase)
      await userProvider.refreshSessionWithRetry();

      if (!mounted) return;

      // 3) Gate de acceso
      if (!userProvider.isAuthorized) {
        await Authentication.signOut();
        userProvider.setUser(null);
        if (!mounted) return;
        setState(() => _accessDenied = true);
        return;
      }

      // 4) Navegar — roles y selectedWorkerId ya están correctos
      context.read<AdminNavProvider>().setTab(0);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigationComponent()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double carouselHeight = size.height * 0.45;
    final String bgAsset = imgAssets[_currentIndex % imgAssets.length];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Image.asset(bgAsset, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.75)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: carouselHeight,
                  width: size.width,
                  child: GestureDetector(
                    onTapDown: (_) => _isUserInteracting = true,
                    onTapUp: (_) => _isUserInteracting = false,
                    onTapCancel: () => _isUserInteracting = false,
                    onHorizontalDragStart: (_) => _isUserInteracting = true,
                    onHorizontalDragEnd: (_) => _isUserInteracting = false,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (page) => setState(
                          () => _currentIndex = page % imgAssets.length),
                      itemBuilder: (_, index) => BannerImages(
                        height: carouselHeight,
                        width: size.width,
                        image: imgAssets[index % imgAssets.length],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imgAssets.length, (i) {
                      final bool active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 5,
                        width: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: active
                              ? const Color(0xff721c80).withOpacity(0.8)
                              : Colors.grey.withOpacity(0.8),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(S.of(context).title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(S.of(context).intro,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 30, left: 24, right: 24),
                  child: Column(
                    children: [
                      if (_accessDenied)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lock_outline,
                                    color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Acceso no autorizado. Tu cuenta Google '
                                    'no está registrada como trabajadora.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _handleGoogleSignIn,
                        child: Container(
                          height: 50,
                          width: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff721c80),
                                Color.fromARGB(255, 196, 103, 169),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: _authLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(S.of(context).start,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BannerImages extends StatelessWidget {
  final String image;
  final double height;
  final double width;
  const BannerImages(
      {super.key,
      required this.image,
      required this.height,
      required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRect(
        child: Image.asset(image,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image,
                    color: Colors.black45, size: 48))),
      ),
    );
  }
}
