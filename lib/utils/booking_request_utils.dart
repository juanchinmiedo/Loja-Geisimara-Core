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
}
