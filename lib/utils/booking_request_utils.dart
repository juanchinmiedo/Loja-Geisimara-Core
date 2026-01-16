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

  static int minutesFromMidnight(TimeOfDay t) => t.hour * 60 + t.minute;

  static Map<String, int> range(TimeOfDay start, TimeOfDay end) => {
        "startMin": minutesFromMidnight(start),
        "endMin": minutesFromMidnight(end),
      };

  // ─────────────────────────────────────────────────────────────
  // NEW: ID helpers
  // ─────────────────────────────────────────────────────────────

  /// slug simple: lower, quita espacios raros, deja a-z0-9 y _
  static String slug(String input) {
    var s = input.trim().toLowerCase();

    // reemplazos básicos de acentos comunes (pt/es)
    const map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c',
    };
    map.forEach((k, v) => s = s.replaceAll(k, v));

    // espacios/guiones -> _
    s = s.replaceAll(RegExp(r'\s+'), '_');
    s = s.replaceAll('-', '_');

    // elimina todo lo que no sea a-z 0-9 _
    s = s.replaceAll(RegExp(r'[^a-z0-9_]+'), '');

    // evita ____ repetidos
    s = s.replaceAll(RegExp(r'_+'), '_');

    // sin _ al principio/final
    s = s.replaceAll(RegExp(r'^_+'), '');
    s = s.replaceAll(RegExp(r'_+$'), '');

    return s.isEmpty ? 'unknown' : s;
  }

  /// Construye el ID base: <cliente>_<YYYYMMDD>_<procedimiento>
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

  /// Devuelve un DocumentReference con fallback _2, _3... si el id ya existe.
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

    // fallback final (rarísimo)
    return col.doc();
  }
}
