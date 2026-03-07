import 'package:flutter/material.dart';

class TimeOfDayUtils {
  static int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static TimeOfDay fromMinutes(int minutes) {
    final safe = minutes.clamp(0, (24 * 60) - 1);
    return TimeOfDay(hour: safe ~/ 60, minute: safe % 60);
  }

  static TimeOfDay roundToStep(TimeOfDay t, {int step = 5}) {
    final total = toMinutes(t);
    final rounded = ((total / step).round()) * step;
    return fromMinutes(rounded);
  }

  static int roundUpMinutes(int minutes, {int step = 5}) {
    if (step <= 1) return minutes;
    final rem = minutes % step;
    return rem == 0 ? minutes : minutes + (step - rem);
  }

  static TimeOfDay clamp(
    TimeOfDay t, {
    required int minMinutes,
    required int maxMinutes,
  }) {
    final clamped = toMinutes(t).clamp(minMinutes, maxMinutes);
    return fromMinutes(clamped);
  }

  static bool isBefore(TimeOfDay a, TimeOfDay b) => toMinutes(a) < toMinutes(b);
  static bool isAfter(TimeOfDay a, TimeOfDay b) => toMinutes(a) > toMinutes(b);

  static String format24h(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
