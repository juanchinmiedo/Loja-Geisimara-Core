import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/utils/localization_helper.dart';

ImageProvider _workerImageProvider(String path) {
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  } else if (path.startsWith('http')) {
    return NetworkImage(path);
  } else {
    return const AssetImage('assets/workers/placeholder.png');
  }
}

class WorkerDetailScreen extends StatelessWidget {
  final String workerId;
  final String workerName;
  final String workerImg;

  const WorkerDetailScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerImg,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            workerName,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff721c80),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,      // 🔥 subrayado blanco
            indicatorWeight: 3,
            labelColor: Colors.white,          // pestaña activa → texto blanco
            unselectedLabelColor: Colors.white70, // inactiva → blanco apagado
            tabs: [
              Tab(text: s.tabInfo),
              Tab(text: s.tabPortfolio),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _WorkerInfoTab(
              workerId: workerId,
              workerImg: workerImg,
            ),
            _WorkerPortfolioTab(
              workerId: workerId,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerInfoTab extends StatelessWidget {
  final String workerId;
  final String workerImg;

  const _WorkerInfoTab({
    required this.workerId,
    required this.workerImg,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(s.workerNotFound),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] as String? ?? '';
        final role = data['role'] as String? ?? '';
        final bio = data['bio'] as String? ?? '';

        final servicesDynamic =
            (data['serviceIds'] as List<dynamic>?) ?? [];
        final serviceIds =
            servicesDynamic.map((e) => e.toString()).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(80),
                  child: Image(
                    image: _workerImageProvider(workerImg),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (role.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (bio.isNotEmpty) ...[
                Text(
                  s.aboutMe,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                s.services,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(height: 8),
              _WorkerServicesFullList(serviceIds: serviceIds),
            ],
          ),
        );
      },
    );
  }
}

class _WorkerServicesFullList extends StatelessWidget {
  final List<String> serviceIds;

  const _WorkerServicesFullList({
    required this.serviceIds,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (serviceIds.isEmpty) {
      return Text(
        s.noServicesAssigned,
        style: const TextStyle(color: Colors.grey),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('services')
          .where(FieldPath.documentId, whereIn: serviceIds)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xff721c80),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>? ?? {};
            final nameKey =
                data['name'] as String? ?? '';
            final name =
                trServiceOrAddon(context, nameKey);
            final desc =
                data['description'] as String? ?? '';
            final price =
                (data['price'] as num?)?.toDouble() ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    if (price > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '€${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff721c80),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WorkerPortfolioTab extends StatelessWidget {
  final String workerId;

  const _WorkerPortfolioTab({
    required this.workerId,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .doc(workerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: Colors.purple),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(s.workerNotFound),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final rawList =
            (data['portfolio'] as List<dynamic>?) ?? [];
        final photos =
            rawList.map((e) => e.toString()).toList();

        if (photos.isEmpty) {
          return Center(
            child: Text(s.noPhotos),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,       // 2 columnas, fotos grandes
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3 / 4, // proporción vertical agradable
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final imgPath = photos[index];

            return GestureDetector(
              onTap: () {
                _openFullScreenCarousel(
                  context: context,
                  photos: photos,
                  initialIndex: index,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: _workerImageProvider(imgPath),
                      fit: BoxFit.cover,
                    ),
                    // degradado abajo
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // pequeño icono de zoom
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFullScreenCarousel({
    required BuildContext context,
    required List<String> photos,
    required int initialIndex,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) {
        return _PortfolioFullScreen(
          photos: photos,
          initialIndex: initialIndex,
        );
      },
    );
  }
}

class _PortfolioFullScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PortfolioFullScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PortfolioFullScreen> createState() =>
      _PortfolioFullScreenState();
}

class _PortfolioFullScreenState
    extends State<_PortfolioFullScreen> {
  static const int _virtualPageCount = 1000000; // para loop “infinito”
  late final PageController _pageController;
  late int _currentVirtualPage;

  int get _realCount => widget.photos.length;

  @override
  void initState() {
    super.initState();
    // Centramos el loop y ajustamos para empezar en initialIndex
    final mid = _virtualPageCount ~/ 2;
    _currentVirtualPage =
        mid - (mid % _realCount) + widget.initialIndex;
    _pageController = PageController(
      initialPage: _currentVirtualPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _realIndexFromVirtual(int virtualIndex) {
    return virtualIndex % _realCount;
  }

  @override
  Widget build(BuildContext context) {
    final realIndex =
        _realIndexFromVirtual(_currentVirtualPage);
    final currentNumber = realIndex + 1;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Carrusel con zoom
              PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentVirtualPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final real =
                      _realIndexFromVirtual(index);
                  final imgPath =
                      widget.photos[real];

                  return Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image(
                          image:
                              _workerImageProvider(imgPath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Botón cerrar
              Positioned(
                top: 12,
                left: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Contador centrado abajo: “3 / 10”
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$currentNumber / $_realCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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