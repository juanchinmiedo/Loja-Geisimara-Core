import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/generated/l10n.dart';

class AllServicesScreen extends StatelessWidget {
  const AllServicesScreen({super.key});

  ImageProvider _imageProviderFrom(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return const AssetImage('assets/services/placeholder.png');
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
          s.Aservices,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
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
                '${s.errorLoadingServices}: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(s.noServicesFound),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final img = _getField<String>(
                doc,
                'img',
                'assets/services/placeholder.png',
              );
              final nameKey = _getField<String>(doc, 'name', '');
              final name = trServiceOrAddon(context, nameKey);
              final categoryKey =
                  _getField<String>(doc, 'category', 'hands');
              final categoryTranslated =
                  trServiceOrAddon(context, categoryKey);
              final price =
                  _getField<num>(doc, 'price', 0).toDouble();
              final isBest = _getField<bool>(doc, 'best', false);

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias, // 🔥 ripple redondeado
                child: ListTile(
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
                      if (isBest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff721c80),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.category}: $categoryTranslated',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price == 0
                            ? s.priceOnRequest
                            : '€${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff721c80),
                          fontWeight: FontWeight.w600,
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