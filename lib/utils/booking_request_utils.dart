import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingRequestUtils {
  static DateTime roundTo5Min(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    final m = d.minute;
    final rounded = ((m + 2) ~/ 5) * 5; // round al múltiplo de 5
    final base = DateTime(d.year, d.month, d.day, d.hour, 0);
    final res = base.add(Duration(minutes: rounded));
    return DateTime(res.year, res.month, res.day, res.hour, res.minute, 0);
  }

  static Timestamp tsRounded(DateTime dt) {
    final r = roundTo5Min(dt);
    return Timestamp.fromDate(r);
  }

  static String yyyymmdd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return "$y$m$d";
  }

  static DateTime? parseYyyymmdd(String s) {
    final clean = s.trim();
    if (clean.length != 8) return null;
    final y = int.tryParse(clean.substring(0, 4));
    final m = int.tryParse(clean.substring(4, 6));
    final d = int.tryParse(clean.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static int minutesFromMidnight(TimeOfDay t) => t.hour * 60 + t.minute;

  static Map<String, int> range(TimeOfDay start, TimeOfDay end) => {
        "startMin": minutesFromMidnight(start),
        "endMin": minutesFromMidnight(end),
      };

  // label worker: igual lógica que tu WorkerSelectorPills
  static String workerLabelFrom(Map<String, dynamic> data, String id) {
    final ns = data["nameShown"];
    if (ns is String && ns.trim().isNotEmpty) return ns.trim();
    final name = data["name"];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return id;
  }

  /// slug simple: lower, quita espacios raros, deja a-z0-9 y _
  static String slug(String input) {
    var s = input.trim().toLowerCase();

    const map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));

    s = s.replaceAll(RegExp(r'\s+'), '_');
    s = s.replaceAll('-', '_');
    s = s.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_+'), '');
    s = s.replaceAll(RegExp(r'_+$'), '');

    return s.isEmpty ? 'unknown' : s;
  }

  static String appointmentBaseId({
    required String clientName,
    required DateTime date,
    required String serviceName,
  }) {
    final datePart = yyyymmdd(date);
    final clientPart = slug(clientName);
    final servicePart = slug(serviceName);
    return "${datePart}_${clientPart}_${servicePart}";
  }

  static Future<DocumentReference<Map<String, dynamic>>> uniqueAppointmentRef({
    required FirebaseFirestore db,
    required String baseId,
    int maxTries = 50,
  }) async {
    final col = db.collection('appointments');

    for (int i = 1; i <= maxTries; i++) {
      final id = (i == 1) ? baseId : "${baseId}_$i";
      final ref = col.doc(id);
      final snap = await ref.get();
      if (!snap.exists) return ref;
    }

    return col.doc();
  }

  static String formatYyyyMmDdToDdMmYyyy(String yyyymmdd) {
    if (yyyymmdd.length != 8) return yyyymmdd;
    final y = yyyymmdd.substring(0, 4);
    final m = yyyymmdd.substring(4, 6);
    final d = yyyymmdd.substring(6, 8);
    return "$d/$m/$y";
  }

  static String bookingRequestBaseId({
    required String clientName,
    required DateTime date,
    required String serviceName,
    String? workerId, // null => any
  }) {
    final datePart = yyyymmdd(date);
    final clientPart = slug(clientName);
    final servicePart = slug(serviceName);
    final workerPart = (workerId == null || workerId.trim().isEmpty) ? "" : "_${slug(workerId)}";
    return "${datePart}_${clientPart}_${servicePart}${workerPart}_request";
  }
}