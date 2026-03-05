import 'package:flutter/material.dart';

class PendingConfirmationUtils {
  /// Firestore field name
  static const String kField = 'pendingConfirmation';

  /// Grey used in calendar blocks when pending
  static const Color pendingColor = Color(0xFF9E9E9E);

  /// Grey-ish background used in list cards when pending
  static const Color pendingCardBg = Color(0xFFF2F2F2);

  /// Convenience: read the pending flag safely (backward compatible)
  static bool isPending(Map<String, dynamic>? data) {
    if (data == null) return false;
    final v = data[kField];
    return v == true;
  }

  /// Prefix for titles (calendar / compact blocks)
  static String withPrefix(String title, bool pending) {
    return pending ? '⏳ $title' : title;
  }

  /// Calendar color resolver
  static Color calendarColor({
    required bool pending,
    required Color normalColor,
  }) {
    return pending ? pendingColor : normalColor;
  }
}