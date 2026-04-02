import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/components/service_type_selectors.dart';

import 'package:salon_app/widgets/booking_request_multi_pickers_pills.dart';
import 'package:salon_app/widgets/worker_choice_pills.dart';
import 'package:salon_app/utils/keyboard_utils.dart';

/// Simple create form:
/// - Procedure dropdown (required) — muestra error inline si se intenta guardar sin seleccionar
/// - Worker choice (Any or specific)
/// - Day + time range pills
class BookingRequestCreateForm extends StatefulWidget {
  const BookingRequestCreateForm({
    super.key,
    required this.selectedWorkerId,
    required this.onWorkerChanged,

    required this.selectedServiceId,
    required this.onServiceChanged,

    required this.selectedDays,
    required this.selectedRanges,
    required this.onAddDay,
    required this.onRemoveDayKey,
    required this.onAddRange,
    required this.onRemoveRangeAt,

    required this.onCreate,
    this.purple = const Color(0xff721c80),
  });

  final String? selectedWorkerId;
  final ValueChanged<String?> onWorkerChanged;

  final String? selectedServiceId;
  final ValueChanged<String?> onServiceChanged;

  final List<String> selectedDays; // yyyymmdd
  final List<Map<String, int>> selectedRanges; // {startMin,endMin}
  final Future<void> Function() onAddDay;
  final void Function(String dayKey) onRemoveDayKey;
  final Future<void> Function() onAddRange;
  final void Function(int index) onRemoveRangeAt;

  final VoidCallback onCreate;
  final Color purple;

  @override
  State<BookingRequestCreateForm> createState() =>
      _BookingRequestCreateFormState();
}

class _BookingRequestCreateFormState extends State<BookingRequestCreateForm> {
  bool _showProcedureError = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final servicesStream =
        FirebaseFirestore.instance.collection('services').snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.procedureLabel,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: servicesStream,
          builder: (context, snap) {
            final docs = snap.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            return Listener(
              onPointerDown: (_) => KeyboardUtils.hide(),
              child: ServiceTypeSelectors(
                services: docs,
                selectedServiceId: widget.selectedServiceId,
                selectedServiceData: null,
                onPickService: (serviceId, serviceData) async {
                  widget.onServiceChanged(serviceId);
                  // Al seleccionar procedimiento, ocultar el error.
                  if (serviceId != null && serviceId.isNotEmpty) {
                    setState(() => _showProcedureError = false);
                  }
                },
                loadingTypes: false,
                serviceTypes: const [],
                selectedType: null,
                onPickType: (_) async {},
              ),
            );
          },
        ),

        // Error inline bajo el selector de procedimiento.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _showProcedureError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 13,
                          color: Colors.red[600]),
                      const SizedBox(width: 4),
                      Text(
                        s.selectProcedureFirst,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),

        Text(s.worker,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        WorkerChoicePills(
          value: widget.selectedWorkerId,
          onChanged: widget.onWorkerChanged,
          anyLabel: s.any,
        ),

        const SizedBox(height: 12),
        BookingRequestMultiPickersPills(
          selectedDays: widget.selectedDays,
          selectedRanges: widget.selectedRanges,
          onAddDay: widget.onAddDay,
          onRemoveDayKey: widget.onRemoveDayKey,
          onAddRange: widget.onAddRange,
          onRemoveRangeAt: widget.onRemoveRangeAt,
          purple: widget.purple,
        ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.purple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              KeyboardUtils.unfocus();
              // Validar procedimiento antes de llamar onCreate.
              if (widget.selectedServiceId == null ||
                  widget.selectedServiceId!.isEmpty) {
                setState(() => _showProcedureError = true);
                return;
              }
              setState(() => _showProcedureError = false);
              widget.onCreate();
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              s.createRequest,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}