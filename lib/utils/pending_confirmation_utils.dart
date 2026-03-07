import 'package:flutter/material.dart';

class PendingConfirmationUtils {
  static const String kField = 'pendingConfirmation';
  static const Color pendingColor = Color(0xFF9E9E9E);
  static const Color pendingCardBg = Color(0xFFF2F2F2);

  static bool isPending(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data[kField] == true;
  }
}
