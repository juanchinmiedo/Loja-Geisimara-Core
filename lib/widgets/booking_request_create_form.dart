import 'package:flutter/material.dart';
import 'package:salon_app/widgets/booking_request_pickers_pills.dart';
import 'package:salon_app/widgets/worker_choice_pills.dart';

/// Shared UI for creating a booking request (same look/UX as Home).
///
/// NOTE: No TextEditingController here (more robust for bottom sheets / rebuilds).
class BookingRequestCreateForm extends StatelessWidget {
  const BookingRequestCreateForm({
    super.key,
    required this.notesValue,
    required this.onNotesChanged,
    required this.notesResetToken,
    required this.selectedWorkerId,
    required this.onWorkerChanged,
    required this.preferredDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onDayChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onCreate,
    this.purple = const Color(0xff721c80),
  });

  /// Current draft notes (state lives in parent)
  final String notesValue;

  /// Called on every edit
  final ValueChanged<String> onNotesChanged;

  /// Change this token (increment) to force field reset (clears UI)
  final int notesResetToken;

  final String? selectedWorkerId;
  final ValueChanged<String?> onWorkerChanged;

  final DateTime? preferredDay;
  final TimeOfDay? rangeStart;
  final TimeOfDay? rangeEnd;
  final ValueChanged<DateTime?> onDayChanged;
  final ValueChanged<TimeOfDay?> onStartChanged;
  final ValueChanged<TimeOfDay?> onEndChanged;

  final VoidCallback onCreate;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey("notes_$notesResetToken"), // ✅ reset reliable
          initialValue: notesValue,
          minLines: 1,
          maxLines: 3,
          onChanged: onNotesChanged,

          // ✅ FIX: tap fuera -> pierde foco y no vuelve a abrir teclado
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },

          decoration: const InputDecoration(
            labelText: "Notes / preferences",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),

        const Text("Worker", style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        WorkerChoicePills(
          value: selectedWorkerId,
          onChanged: onWorkerChanged,
          anyLabel: "Any",
        ),

        const SizedBox(height: 12),
        BookingRequestPickersPills(
          preferredDay: preferredDay,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          onDayChanged: onDayChanged,
          onStartChanged: onStartChanged,
          onEndChanged: onEndChanged,
          purple: purple,
        ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
              onCreate();
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Create request",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}