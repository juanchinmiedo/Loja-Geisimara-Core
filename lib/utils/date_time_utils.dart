import 'package:flutter/material.dart';

class DateTimeUtils {
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

  static String formatYyyyMmDdToDdMmYyyy(String yyyymmdd) {
    if (yyyymmdd.length != 8) return yyyymmdd;
    final y = yyyymmdd.substring(0, 4);
    final m = yyyymmdd.substring(4, 6);
    final d = yyyymmdd.substring(6, 8);
    return "$d/$m/$y";
  }

  static int minutesFromMidnight(TimeOfDay t) => t.hour * 60 + t.minute;

  static String hhmmFromMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return "$h:$m";
  }

  static String formatRangeMinutes({required int startMin, required int endMin}) {
    return "${hhmmFromMinutes(startMin)}-${hhmmFromMinutes(endMin)}";
  }
}
