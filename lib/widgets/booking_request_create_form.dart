import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:salon_app/components/service_type_selectors.dart';

import 'package:salon_app/widgets/booking_request_multi_pickers_pills.dart';
import 'package:salon_app/widgets/worker_choice_pills.dart';

/// Simple create form:
/// - Procedure dropdown (required)
/// - Worker choice (Any or specific)
/// - Day + time range pills
class BookingRequestCreateForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final servicesStream = FirebaseFirestore.instance.collection('services').snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Procedure", style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: servicesStream,
          builder: (context, snap) {
            final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            return Listener(
              onPointerDown: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                SystemChannels.textInput.invokeMethod('TextInput.hide');
              },
              child: ServiceTypeSelectors(
                services: docs, // ✅ lista de services (QueryDocumentSnapshot)
                selectedServiceId: selectedServiceId,
                selectedServiceData: null, // ✅ aquí no la necesitamos para booking request
                onPickService: (serviceId, serviceData) async {
                  // ✅ mantenemos tu API actual (onServiceChanged solo recibe serviceId)
                  onServiceChanged(serviceId);
                },

                // ✅ booking request NO usa types => lo dejamos vacío
                loadingTypes: false,
                serviceTypes: const [],
                selectedType: null,
                onPickType: (_) async {},
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        const Text("Worker", style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        WorkerChoicePills(
          value: selectedWorkerId,
          onChanged: onWorkerChanged,
          anyLabel: "Any",
        ),

        const SizedBox(height: 12),
        BookingRequestMultiPickersPills(
          selectedDays: selectedDays,
          selectedRanges: selectedRanges,
          onAddDay: onAddDay,
          onRemoveDayKey: onRemoveDayKey,
          onAddRange: onAddRange,
          onRemoveRangeAt: onRemoveRangeAt,
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