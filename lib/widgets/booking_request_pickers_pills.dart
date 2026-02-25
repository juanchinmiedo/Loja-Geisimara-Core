import 'package:flutter/material.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/components/ui/app_icon_value_pill_button.dart';

class BookingRequestPickersPills extends StatelessWidget {
  const BookingRequestPickersPills({
    super.key,
    required this.preferredDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onDayChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    this.purple = const Color(0xff721c80),
  });

  final DateTime? preferredDay;
  final TimeOfDay? rangeStart;
  final TimeOfDay? rangeEnd;

  final ValueChanged<DateTime?> onDayChanged;
  final ValueChanged<TimeOfDay?> onStartChanged;
  final ValueChanged<TimeOfDay?> onEndChanged;

  final Color purple;

  // límites (mismos que Home)
  static const int _startMin = 7 * 60 + 30;
  static const int _startMax = 19 * 60;
  static const int _endMin = 9 * 60;
  static const int _endMax = 21 * 60;

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMin(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23);
    final m = (minutes % 60).clamp(0, 59);
    return TimeOfDay(hour: h, minute: m);
  }

  TimeOfDay _clampTime(TimeOfDay t, int min, int max) {
    final v = _toMin(t);
    final clamped = v.clamp(min, max);
    return _fromMin(clamped);
  }

  String _ddmmyyyy(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return "$dd/$mm/$yy";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final showIcons = c.maxWidth >= 340;

        Future<void> pickDay() async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final d = await showDatePicker(
            context: context,
            firstDate: today,
            lastDate: DateTime(now.year + 2),
            initialDate: preferredDay ?? today,
          );
          if (d != null) onDayChanged(d);
        }

        Future<void> pickStart() async {
          final initial = rangeStart ?? const TimeOfDay(hour: 9, minute: 0);
          final t = await showTimePicker(context: context, initialTime: initial);
          if (t == null) return;

          final fixedStart = _clampTime(t, _startMin, _startMax);
          onStartChanged(fixedStart);

          // si end existe y queda < start => empuja end hacia start
          if (rangeEnd != null && _toMin(rangeEnd!) < _toMin(fixedStart)) {
            final adjustedEnd = _clampTime(fixedStart, _endMin, _endMax);
            onEndChanged(adjustedEnd);
          }
        }

        Future<void> pickEnd() async {
          TimeOfDay initial;
          if (rangeStart != null) {
            final startMin = _toMin(rangeStart!);
            final minAllowed = startMin < _endMin ? _endMin : startMin;
            initial = _fromMin(minAllowed);
          } else {
            initial = rangeEnd ?? const TimeOfDay(hour: 12, minute: 0);
          }

          final t = await showTimePicker(context: context, initialTime: initial);
          if (t == null) return;

          final fixedEnd = _clampTime(t, _endMin, _endMax);

          // ensure end >= start
          if (rangeStart != null && _toMin(fixedEnd) < _toMin(rangeStart!)) {
            onEndChanged(_clampTime(rangeStart!, _endMin, _endMax));
          } else {
            onEndChanged(fixedEnd);
          }
        }

        Widget dayWidget() {
          if (preferredDay == null) {
            return AppIconPillButton(
              icon: Icons.calendar_month,
              color: purple,
              shadow: false,
              tooltip: "Pick preferred day",
              onTap: pickDay,
            );
          }
          return AppIconValuePillButton(
            color: purple,
            icon: Icons.calendar_month,
            showIcon: showIcons,
            label: _ddmmyyyy(preferredDay!),
            shadow: false,
            onTap: pickDay,
          );
        }

        Widget startWidget() {
          if (rangeStart == null) {
            return AppIconPillButton(
              icon: Icons.schedule,
              color: purple,
              shadow: false,
              tooltip: "Pick start time",
              onTap: pickStart,
            );
          }
          return AppIconValuePillButton(
            color: purple,
            icon: Icons.schedule,
            showIcon: true,
            label: rangeStart!.format(context),
            shadow: false,
            onTap: pickStart,
          );
        }

        Widget endWidget() {
          if (rangeEnd == null) {
            return AppIconPillButton(
              icon: Icons.alarm_on,
              color: purple,
              shadow: false,
              tooltip: "Pick end time",
              onTap: pickEnd,
            );
          }
          return AppIconValuePillButton(
            color: purple,
            icon: Icons.alarm_on,
            showIcon: true,
            label: rangeEnd!.format(context),
            shadow: false,
            onTap: pickEnd,
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            dayWidget(),
            startWidget(),
            endWidget(),
          ],
        );
      },
    );
  }
}