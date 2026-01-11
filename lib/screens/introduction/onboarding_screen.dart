import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/components/bottom_navigationbar.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/controller/auth_controller.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  // ----- CONTROLADORES -----
  static const int _kLoopBase = 1000;
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;

  bool _authLoading = false;

  // ----- DATOS -----
  final List<String> imgAssets = [
    'assets/onBoarding_1.jpg',
    'assets/onBoarding_2.jpg',
    'assets/onBoarding_2.jpg',
  ];

  @override
  void initState() {
    super.initState();

    final startPage =
        _kLoopBase * (imgAssets.isEmpty ? 1 : imgAssets.length);
    _pageController = PageController(
      initialPage: startPage,
      viewportFraction: 1.0,
    );
    _currentIndex = startPage % imgAssets.length;

    // ---- AUTO-PLAY cada 4 s ----
    _autoPlayTimer =
        Timer.periodic(const Duration(seconds: 4), (timer) {
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
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);

    try {
      setState(() => _authLoading = true);

      final user = await Authentication.signInWithGoogle(
          context: context);
      if (user == null) {
        setState(() => _authLoading = false);
        return; // usuario canceló o fallo
      }

      userProvider.setUser(user);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => const BottomNavigationComponent(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _authLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => const BottomNavigationComponent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    final double carouselHeight = height * 0.45;

    // Ruta asset actual para el fondo
    final String bgAsset =
        imgAssets[_currentIndex % imgAssets.length];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // --------- FONDO DIFUMINADO (ASSET) ---------
          Positioned.fill(
            child: ImageFiltered(
              imageFilter:
                  ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Image.asset(
                bgAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.75),
            ),
          ),

          // --------- CONTENIDO ---------
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ---------- CARRUSEL ----------
              SizedBox(
                height: carouselHeight,
                width: width,
                child: GestureDetector(
                  onTapDown: (_) => _isUserInteracting = true,
                  onTapUp: (_) => _isUserInteracting = false,
                  onHorizontalDragStart: (_) =>
                      _isUserInteracting = true,
                  onHorizontalDragEnd: (_) =>
                      _isUserInteracting = false,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() =>
                          _currentIndex = page % imgAssets.length);
                    },
                    itemBuilder: (context, index) {
                      final assetPath =
                          imgAssets[index % imgAssets.length];
                      return BannerImages(
                        height: carouselHeight,
                        width: width,
                        image: assetPath,
                      );
                    },
                  ),
                ),
              ),

              // ---------- INDICADORES ----------
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children:
                      List.generate(imgAssets.length, (i) {
                    final bool active =
                        i == _currentIndex;
                    return AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6),
                      height: 5,
                      width: 30,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(20),
                        color: active
                            ? const Color(0xff721c80)
                                .withOpacity(0.8)
                            : Colors.grey.withOpacity(0.8),
                      ),
                    );
                  }),
                ),
              ),

              // ---------- TEXTOS ----------
              Text(
                S.of(context).title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                S.of(context).intro,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),

              // ---------- BOTONES ----------
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 30, left: 24, right: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handleGoogleSignIn,
                      child: Container(
                        height: 50,
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xff721c80),
                              Color.fromARGB(
                                  255, 196, 103, 169),
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
                                  child:
                                      CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  S.of(context).start,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _continueAsGuest,
                      child: Text(
                        // puedes traducir esto con una key tipo "continueAsGuest"
                        'Continue as guest',
                        style: const TextStyle(
                          color: Color(0xff721c80),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- COMPONENTE DE IMAGEN ----------
class BannerImages extends StatelessWidget {
  final String image; // ruta asset tipo 'assets/photo1.jpg'
  final double height;
  final double width;

  const BannerImages({
    Key? key,
    required this.image,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRect(
        child: Image.asset(
          image,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: width,
          height: height,
          errorBuilder: (ctx, err, stack) => const Center(
            child: Icon(Icons.broken_image,
                color: Colors.black45, size: 48),
          ),
        ),
      ),
    );
  }
}