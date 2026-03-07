import 'package:flutter/material.dart';

import 'package:salon_app/components/bounded_time_picker.dart';
import 'package:salon_app/utils/time_of_day_utils.dart';

class AppTimePicker {
  static Future<TimeOfDay?> pick5m({
    required BuildContext context,
    required TimeOfDay initial,
    bool use24h = true,
    bool bounded = false,
    VoidCallback? onSnap,
  }) async {
    if (bounded) {
      return BoundedTimePicker.show(
        context: context,
        initialTime: initial,
        minuteStep: 5,
        use24h: use24h,
        hapticsOnSnap: true,
        onSnapped: (_, __) => onSnap?.call(),
      );
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: use24h,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;
    return TimeOfDayUtils.roundToStep(picked, step: 5);
  }
}
