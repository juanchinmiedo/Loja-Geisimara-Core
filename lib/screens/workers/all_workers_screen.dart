import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/screens/workers/worker_detail_screen.dart';

class AllWorkersScreen extends StatelessWidget {
  const AllWorkersScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.Aspecialists,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workers')
            .orderBy('best', descending: true)
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          final s = S.of(context);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${s.errorLoadingSpecialists}: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(s.noSpecialistsFound),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final workerId = doc.id;
              final img = _getField<String>(
                doc,
                'img',
                'assets/workers/placeholder.png',
              );
              final name = _getField<String>(doc, 'name', 'Sin nombre');
              final best = _getField<bool>(doc, 'best', false);

              final servicesDynamic =
                  _getField<List<dynamic>>(doc, 'serviceIds', []);
              final serviceIds =
                  servicesDynamic.map((e) => e.toString()).toList();
              final serviceCount = serviceIds.length;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias, // 🔥 el ripple respeta el borde
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent, // 🔥 sin líneas finas
                  ),
                  child: ExpansionTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: _imageProviderFrom(img),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (best)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff721c80),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BEST', // se mantiene fijo
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      serviceCount == 0
                          ? '${s.services}: 0'
                          : '$serviceCount ${s.services}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      _WorkerServicesPreview(serviceIds: serviceIds),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkerDetailScreen(
                                  workerId: workerId,
                                  workerName: name,
                                  workerImg: img,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xff721c80),
                          ),
                          label: Text(
                            s.viewProfileAndCatalog,
                            style: const TextStyle(color: Color(0xff721c80)),
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
      ),
    );
  }
}

class _WorkerServicesPreview extends StatelessWidget {
  final List<String> serviceIds;

  const _WorkerServicesPreview({
    super.key,
    required this.serviceIds,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    if (serviceIds.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${s.services}: 0',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('services')
          .where(FieldPath.documentId, whereIn: serviceIds)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final data =
                doc.data() as Map<String, dynamic>? ?? {};
            final nameKey = data['name'] as String? ?? '';
            final name = trServiceOrAddon(context, nameKey);
            final desc = data['description'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: Color(0xff721c80))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (desc.isNotEmpty)
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}