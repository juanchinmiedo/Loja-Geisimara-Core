import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BoundedTimePicker {
  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static TimeOfDay _fromMinutes(int m) {
    final mm = m % (24 * 60);
    final h = mm ~/ 60;
    final min = mm % 60;
    return TimeOfDay(hour: h, minute: min);
  }

  static int _snapToStep(int minutes, int step) {
    // redondeo al múltiplo más cercano (ej: 5)
    final snapped = ((minutes + (step ~/ 2)) ~/ step) * step;
    final safe = snapped % (24 * 60);
    return safe;
  }

  /// ✅ TimePicker NATIVO (dial + toggle a teclado)
  /// ✅ Snap silencioso al confirmar (OK)
  /// ✅ Opcional: haptic + callback si hubo snap
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    int minuteStep = 5,
    bool use24h = true,

    /// Si true: vibración ligera cuando el minuto se corrige
    bool hapticsOnSnap = false,

    /// Callback solo si hubo ajuste (picked != snapped)
    void Function(TimeOfDay picked, TimeOfDay snapped)? onSnapped,
  }) async {
    // Asegura que el initial ya entra snappeado para que no “empiece raro”
    final initM = _toMinutes(initialTime);
    final initSnap = _fromMinutes(_snapToStep(initM, minuteStep));

    final picked = await showTimePicker(
      context: context,
      initialTime: initSnap,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (ctx, child) {
        final media = MediaQuery.of(ctx);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: use24h),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return null;

    final pickedM = _toMinutes(picked);
    final snappedM = _snapToStep(pickedM, minuteStep);
    final snapped = _fromMinutes(snappedM);

    final didSnap = picked.hour != snapped.hour || picked.minute != snapped.minute;

    if (didSnap) {
      if (hapticsOnSnap) {
        HapticFeedback.selectionClick();
      }
      onSnapped?.call(picked, snapped);
    }

    return snapped;
  }
}
