import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceTypesUtils {
  static Future<List<Map<String, dynamic>>> loadSortedTypes({
    required FirebaseFirestore firestore,
    required String serviceId,
  }) async {
    if (serviceId.isEmpty) return const [];

    final snap = await firestore
        .collection('services')
        .doc(serviceId)
        .collection('types')
        .get();

    final types = snap.docs.map((d) {
      final data = d.data();
      return {
        ...data,
        '_id': d.id,
      };
    }).toList(growable: false);

    bool isCommon(Map<String, dynamic> type) => type['common'] == true;

    types.sort((a, b) {
      final ac = isCommon(a) ? 0 : 1;
      final bc = isCommon(b) ? 0 : 1;
      if (ac != bc) return ac - bc;

      final al = (a['label'] ?? a['name'] ?? a['_id'] ?? '').toString().toLowerCase();
      final bl = (b['label'] ?? b['name'] ?? b['_id'] ?? '').toString().toLowerCase();
      return al.compareTo(bl);
    });

    return types;
  }

  static Map<String, dynamic>? pickDefaultType(List<Map<String, dynamic>> types) {
    if (types.isEmpty) return null;
    return types.firstWhere(
      (type) => type['common'] == true,
      orElse: () => types.first,
    );
  }

  static Map<String, dynamic>? findById(List<Map<String, dynamic>> types, String id) {
    if (id.isEmpty) return null;
    for (final type in types) {
      if ((type['_id'] ?? '').toString() == id) return type;
    }
    return null;
  }

  static Map<String, dynamic>? findByKey(List<Map<String, dynamic>> types, String key) {
    if (key.isEmpty) return null;
    for (final type in types) {
      final currentKey = (type['nameKey'] ?? type['_id'] ?? type['key'] ?? '').toString();
      if (currentKey == key) return type;
    }
    return null;
  }

  static double finalPriceSmart({
    required Map<String, dynamic>? service,
    required Map<String, dynamic>? type,
    required List<Map<String, dynamic>> loadedTypes,
  }) {
    final base = service?['price'];
    final basePrice = base is num ? base.toDouble() : 0.0;
    if (loadedTypes.isEmpty) return basePrice;

    final extra = type?['extraPrice'];
    final extraPrice = extra is num ? extra.toDouble() : 0.0;
    return basePrice + extraPrice;
  }

  static int finalMinutesSmart({
    required Map<String, dynamic>? service,
    required Map<String, dynamic>? type,
    required List<Map<String, dynamic>> loadedTypes,
  }) {
    if (loadedTypes.isNotEmpty) {
      final value = type?['durationMin'];
      return value is num ? value.toInt() : 0;
    }

    final value = service?['durationMin'];
    return value is num ? value.toInt() : 0;
  }
}
