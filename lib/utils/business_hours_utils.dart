import 'package:flutter/material.dart';

import 'package:salon_app/utils/time_of_day_utils.dart';

class BusinessHoursUtils {
  static const int defaultMinStartMin = 7 * 60;
  static const int defaultMaxEndMin = 21 * 60;

  static TimeOfDay clampStartToBusinessHours(
    TimeOfDay picked, {
    required int durationMin,
    int minStartMin = defaultMinStartMin,
    int maxEndMin = defaultMaxEndMin,
  }) {
    var start = TimeOfDayUtils.toMinutes(picked);
    if (start < minStartMin) start = minStartMin;

    var latestStart = maxEndMin - durationMin;
    if (latestStart < minStartMin) latestStart = minStartMin;
    if (start > latestStart) start = latestStart;

    return TimeOfDayUtils.fromMinutes(start);
  }
}
