import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:math' as math;

import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/utils/localization_helper.dart';

import 'package:salon_app/provider/admin_mode_provider.dart';
import 'package:salon_app/utils/role_helper.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/provider/locale_provider.dart';
import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/screens/introduction/spalsh_screen.dart';
import 'package:salon_app/screens/services/all_services_screen.dart';
import 'package:salon_app/screens/workers/all_workers_screen.dart';
import 'package:salon_app/screens/workers/worker_detail_screen.dart';
import 'package:salon_app/components/searchbar.dart' as custom_search;

import '../../components/carousel.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onBookNow;

  const HomeScreen({
    super.key,
    this.onBookNow,
  });

  ImageProvider _imageProviderFrom(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return const AssetImage('assets/workers/placeholder.png');
    }
  }

  T _getField<T>(QueryDocumentSnapshot doc, String key, T fallback) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return fallback;
      final value = data[key];
      if (value == null) return fallback;
      return value is T ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!context.mounted) return;
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.openUrlError(url))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xff721c80),
                          Color.fromARGB(255, 196, 103, 169),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    child: const Padding(
                      padding:
                       EdgeInsets.only(top: 38, left: 18, right: 18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Tondela - PT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Spacer(),

                              _LanguageSelector(),
                              SizedBox(width: 12),
                              _HomeProfileAvatar(),
                            ],
                          ),
                          custom_search.SearchBar(),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Carousel(
                    onBookNow: onBookNow,
                  ),
                ),
              ],
            ),

            // --------- Best Services ---------
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Column(
                children: [
                  const HorizontalText(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('services')
                        .where('best', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final s = S.of(context);

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.purple);
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "${s.errorLoadingServices}: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.noServicesFound,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final img = _getField<String>(
                              doc,
                              "img",
                              "assets/services/placeholder.png",
                            );

                            final nameKey =
                                _getField<String>(doc, "name", "");
                            final name = trServiceOrAddon(context, nameKey);

                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 18, top: 8),
                              child: SizedBox(
                                width: 80, // ancho uniforme
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(56),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.grey,
                                            blurRadius: 10.0,
                                            spreadRadius: 0.5,
                                            offset: Offset(3.0, 3.0),
                                          )
                                        ],
                                        image: DecorationImage(
                                          image: _imageProviderFrom(img),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --------- Best Specialists ---------
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        s.Bspecialists,
                        style: const TextStyle(
                          color: Color(0xff721c80),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(flex: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllWorkersScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              s.viewAll,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.double_arrow_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('workers')
                        .where('best', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final s = S.of(context);

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.purple);
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "${s.errorLoadingSpecialists}: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            s.noSpecialistsFound,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return SizedBox(
                        height: 170,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final img = _getField<String>(
                              doc,
                              "img",
                              "assets/workers/placeholder.png",
                            );
                            final name =
                                _getField<String>(doc, "name", "Sin nome");

                            // serviceIds del worker (lista de strings)
                            final rawServiceIds =
                                _getField<List<dynamic>>(doc, 'serviceIds', []);
                            final serviceIds =
                                rawServiceIds.map((e) => e.toString()).toList();

                            return _BestWorkerCard(
                              workerId: doc.id,
                              name: name,
                              imagePath: img,
                              serviceIds: serviceIds,
                            );
                          },
                        ),
                      );

                    },
                  ),
                ],
              ),
            ),

            // --------- Footer ---------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 20,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color.fromARGB(255, 220, 218, 218),
                    width: 0.9,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                right: 18,
                left: 18,
                bottom: 20,
              ),
              child: Row(
                children: [
                  // WEB
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _launchUrl(
                          context, "https://www.google.com/finance/portfolio/watchlist"); // tu web
                    },
                    child: const Padding(
                      padding:
                        EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 20,
                            color: Color(0xff721c80),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'www.geisimarasantos.pt',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // TELÉFONO
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _callNumber('+351932769699', context);
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+351 932 769 699',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.phone_in_talk_sharp,
                            size: 20,
                            color: Color(0xff721c80),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizontalText extends StatelessWidget {
  const HorizontalText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(left: 18, right: 18, bottom: 12),
      child: Row(
        children: [
          Text(
            s.Bservices,
            style: const TextStyle(
              color: Color(0xff721c80),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AllServicesScreen(),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  s.viewAll,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  List<Map<String, String>> _languages() {
    return [
      {
        'code': 'en',
        'label': 'English',
        'asset': 'assets/flags/en.png',
      },
      {
        'code': 'es',
        'label': 'Español',
        'asset': 'assets/flags/es.png',
      },
      {
        'code': 'pt',
        'label': 'Português',
        'asset': 'assets/flags/pt.png',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final currentCode = localeProvider.locale.languageCode;
        final allLangs = _languages();

        final current = allLangs.firstWhere(
          (l) => l['code'] == currentCode,
          orElse: () => allLangs.first,
        );

        final langs = <Map<String, String>>[current];
        langs.addAll(
          allLangs.where((l) => l['code'] != current['code']),
        );

        return PopupMenuButton<String>(
          tooltip: 'Language',
          position: PopupMenuPosition.over,
          offset: const Offset(0, -4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (code) {
            localeProvider.setLocaleByLanguageCode(code);
          },
          itemBuilder: (context) {
            return langs.map((lang) {
              final isCurrent = lang['code'] == currentCode;

              return PopupMenuItem<String>(
                value: lang['code']!,
                child: Container(
                  decoration: isCurrent
                      ? BoxDecoration(
                          color: const Color(0xff721c80)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: isCurrent
                        ? [
                            Text(
                              lang['label']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff721c80),
                              ),
                            ),
                            const Spacer(),
                            CircleAvatar(
                              radius: 10,
                              backgroundImage:
                                  AssetImage(lang['asset']!),
                            ),
                          ]
                        : [
                            CircleAvatar(
                              radius: 10,
                              backgroundImage:
                                  AssetImage(lang['asset']!),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang['label']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current['label']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 10,
                  backgroundImage: AssetImage(current['asset']!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyServicesPlaceholder extends StatelessWidget {
  const _EmptyServicesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.cut, 'label': 'Services'},
      {'icon': Icons.brush, 'label': 'Care'},
      {'icon': Icons.star, 'label': 'Best'},
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 18),
        itemBuilder: (context, i) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10.0,
                      spreadRadius: 0.5,
                      offset: Offset(3, 3),
                    )
                  ],
                ),
                child: Icon(
                  items[i]['icon'] as IconData,
                  color: const Color(0xff721c80),
                ),
              ),
              Text(
                items[i]['label'] as String,
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeProfileAvatar extends StatelessWidget {
  const _HomeProfileAvatar();

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user ?? FirebaseAuth.instance.currentUser;

    ImageProvider avatarImage;
    if (user != null && user.photoURL != null) {
      avatarImage = NetworkImage(user.photoURL!);
    } else {
      avatarImage = const AssetImage('assets/logo.png');
    }

    final displayName = user?.displayName ?? S.of(context).guest;
    final email = user?.email ?? '';
    final bool isGuest = user == null;

    final adminMode = context.watch<AdminModeProvider>().enabled;

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 8),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) async {
        if (value == 'login') {
          final newUser = await Authentication.signInWithGoogle(context: context);
          if (newUser != null) {
            userProvider.setUser(newUser);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).googleLoginSuccess)),
              );
            }
          }
        } else if (value == 'logout') {
          await FirebaseAuth.instance.signOut();
          userProvider.setUser(null);
          if (context.mounted) {
            context.read<AdminModeProvider>().reset();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          }
        } else if (value == 'toggle_admin') {
          final can = await RoleHelper.canUseAdminMode();
          if (!can) return;

          final provider = context.read<AdminModeProvider>();
          provider.setEnabled(!provider.enabled);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.enabled ? 'Modo admin activado' : 'Modo usuario activado'),
              ),
            );
          }
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        // Admin mode (solo si admin/staff)
        items.add(
          PopupMenuItem<String>(
            value: 'toggle_admin',
            child: FutureBuilder<bool>(
              future: RoleHelper.canUseAdminMode(),
              builder: (context, snap) {
                final canAdmin = snap.data == true;
                if (!canAdmin) return const SizedBox.shrink();

                return Row(
                  children: [
                    Icon(
                      adminMode ? Icons.person : Icons.admin_panel_settings,
                      size: 18,
                      color: const Color(0xff721c80),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      adminMode ? 'Back to user mode' : 'Start admin mode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff721c80),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Si no es admin, el FutureBuilder devuelve shrink y el item queda vacío; lo limpiamos:
        // (Flutter igual reserva el item si lo devolvemos). Para evitarlo, solo lo añadimos si canAdmin.
        // Pero PopupMenu no permite async en itemBuilder. Por eso lo dejamos así de momento.
        // Si te molesta ese hueco, lo hacemos con un botón custom overlay.

        if (isGuest) {
          items.add(
            const PopupMenuItem<String>(
              value: 'login',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 22, color: Color(0xff721c80)),
                  SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xff721c80)),
                  ),
                ],
              ),
            ),
          );
        } else {
          items.add(
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Color(0xff721c80)),
                  SizedBox(width: 8),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff721c80)),
                  ),
                ],
              ),
            ),
          );
        }

        // Filtrar items vacíos (por el shrink)
        return items.where((e) {
          if (e is PopupMenuItem<String>) {
            final child = e.child;
            return !(child is SizedBox && child.height == 0 && child.width == 0);
          }
          return true;
        }).toList();
      },
      child: CircleAvatar(
        radius: 16,
        backgroundImage: avatarImage,
      ),
    );
  }
}


Future<void> _callNumber(String number, BuildContext context) async {
  final uri = Uri(scheme: 'tel', path: number);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el teléfono')),
    );
  }
}

class _BestWorkerCard extends StatefulWidget {
  final String workerId;
  final String name;
  final String imagePath;
  final List<String> serviceIds;

  const _BestWorkerCard({
    Key? key,
    required this.workerId,
    required this.name,
    required this.imagePath,
    required this.serviceIds,
  }) : super(key: key);

  @override
  State<_BestWorkerCard> createState() => _BestWorkerCardState();
}

class _BestWorkerCardState extends State<_BestWorkerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;

          return Container(
            margin: const EdgeInsets.only(right: 12.0),
            height: 160,
            width: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspectiva
                ..rotateY(angle),
              child: angle <= math.pi / 2
                  ? _buildFront(context)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildBack(context),
                    ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- FRONT: foto + nombre ----------------
  Widget _buildFront(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image(
              image: _imageProviderFrom(widget.imagePath),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40,
              color: Colors.black.withOpacity(0.65),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Center(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BACK: servicios + "Ver perfil y catálogo" ----------------
  Widget _buildBack(BuildContext context) {
    final s = S.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          // Fondo semitransparente sobre la foto para mantener coherencia
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.darken,
              ),
              child: Image(
                image: _imageProviderFrom(widget.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Contenido de servicios
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            bottom: 40, // se reserva el espacio del footer
            child: _WorkerServicesBack(
              serviceIds: widget.serviceIds,
            ),
          ),

          // Footer con link a perfil
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40,
              color: Colors.black.withOpacity(0.85),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerDetailScreen(
                      workerId: widget.workerId,
                      workerName: widget.name,
                      workerImg: widget.imagePath,
                    ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    s.viewProfileAndCatalog,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _imageProviderFrom(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return const AssetImage('assets/workers/placeholder.png');
    }
  }
}

class _WorkerServicesBack extends StatelessWidget {
  final List<String> serviceIds;

  const _WorkerServicesBack({
    Key? key,
    required this.serviceIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (serviceIds.isEmpty) {
      return Text(
        s.noServicesAssigned,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      );
    }

    // Firestore whereIn máx 10 IDs
    final limitedIds =
        serviceIds.length > 10 ? serviceIds.sublist(0, 10) : serviceIds;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            s.errorLoadingServices,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            s.noServicesAssigned,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // Construimos lista [best?, label]
        final items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>? ?? {};
          final isBest = (data['best'] as bool?) ?? false;
          final nameKey = (data['name'] as String?) ?? '';
          final label = trServiceOrAddon(context, nameKey);
          return (isBest: isBest, label: label);
        }).toList();

        // 1º los best, luego el resto
        items.sort((a, b) {
          final aBest = a.isBest ? 1 : 0;
          final bBest = b.isBest ? 1 : 0;
          return bBest.compareTo(aBest);
        });

        final labels = items.map((e) => e.label).toList();

        const maxVisible = 4; // máximo que se ven bien
        final visibleLabels = labels.length <= maxVisible
            ? labels
            : labels.take(maxVisible).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final label in visibleLabels)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $label',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (labels.length > maxVisible)
              const Text(
                '...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        );
      },
    );
  }
}