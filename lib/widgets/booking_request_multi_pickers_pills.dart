import 'package:flutter/material.dart';
import 'package:salon_app/components/ui/app_icon_value_pill_button.dart';
import 'package:salon_app/utils/date_time_utils.dart';

/// Multi-day + multi-range picker (simple y sin complicarnos).
/// - "Add day" => añade a [selectedDays]
/// - "+ Add range" => añade a [selectedRanges] (startMin/endMin)
///
/// Las pills son removibles.
class BookingRequestMultiPickersPills extends StatelessWidget {
  const BookingRequestMultiPickersPills({
    super.key,
    required this.selectedDays,
    required this.selectedRanges,
    required this.onAddDay,
    required this.onRemoveDayKey,
    required this.onAddRange,
    required this.onRemoveRangeAt,
    this.purple = const Color(0xff721c80),
  });

  final List<String> selectedDays; // yyyymmdd
  final List<Map<String, int>> selectedRanges; // {startMin,endMin}

  final Future<void> Function() onAddDay;
  final void Function(String dayKey) onRemoveDayKey;

  final Future<void> Function() onAddRange;
  final void Function(int index) onRemoveRangeAt;

  final Color purple;

  @override
  Widget build(BuildContext context) {
    Widget pill({
      required String label,
      required VoidCallback onRemove,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: purple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: purple.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: purple)),
            const SizedBox(width: 8),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close, size: 18, color: purple),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final showIcons = c.maxWidth >= 340;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppIconValuePillButton(
                  color: purple,
                  icon: Icons.calendar_month,
                  showIcon: showIcons,
                  label: "Add day",
                  shadow: false,
                  onTap: onAddDay,
                ),
                AppIconValuePillButton(
                  color: purple,
                  icon: Icons.schedule,
                  showIcon: true,
                  label: "+ Add range",
                  shadow: false,
                  onTap: onAddRange,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (selectedDays.isNotEmpty) ...[
              const Text("Days", style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedDays
                    .map((k) => pill(
                          label: DateTimeUtils.formatYyyyMmDdToDdMmYyyy(k),
                          onRemove: () => onRemoveDayKey(k),
                        ))
                    .toList(growable: false),
              ),
              const SizedBox(height: 10),
            ],

            if (selectedRanges.isNotEmpty) ...[
              const Text("Ranges", style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(selectedRanges.length, (i) {
                  final r = selectedRanges[i];
                  final s = (r['startMin'] ?? 0);
                  final e = (r['endMin'] ?? 0);
                  return pill(
                    label: DateTimeUtils.formatRangeMinutes(startMin: s, endMin: e),
                    onRemove: () => onRemoveRangeAt(i),
                  );
                }),
              ),
            ],

            if (selectedDays.isEmpty && selectedRanges.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Tip: add one or more days, and optionally time ranges.",
                  style: TextStyle(color: Colors.black.withOpacity(0.55)),
                ),
              ),
          ],
        );
      },
    );
  }
}
