import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

/// Reusable compact card for a single booking request.
///
/// Goals:
/// - No overlay/superposition of action buttons.
/// - Keeps the compact look.
/// - Worker shows REAL name if possible (or Any if null).
class BookingRequestCard extends StatelessWidget {
  const BookingRequestCard({
    super.key,
    required this.requestId,
    required this.br,
    required this.purple,
    required this.onDelete,
    required this.onEditNotes,
  });

  final String requestId;
  final Map<String, dynamic> br;
  final Color purple;
  final Future<void> Function() onDelete;
  final VoidCallback onEditNotes;

  String _formatRange(Map<String, dynamic> r) {
    final s = (r['startMin'] as num?)?.toInt() ?? 0;
    final e = (r['endMin'] as num?)?.toInt() ?? 0;
    String hm(int m) =>
        "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";
    return "${hm(s)} - ${hm(e)}";
  }

  Widget _workerLine(String? workerId) {
    if (workerId == null) {
      return const Text("• Worker: Any");
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection("workers").doc(workerId).snapshots(),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() ?? const <String, dynamic>{};
          final label = BookingRequestUtils.workerLabelFrom(data, workerId);
          return Text("• Worker: $label");
        }
        // fallback mientras carga o si no existe
        return Text("• Worker: $workerId");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = (br['preferredDays'] as List?) ?? const [];
    final ranges = (br['preferredTimeRanges'] as List?) ?? const [];
    final notes = (br['notes'] ?? '').toString().trim();
    final workerId = br['workerId'] as String?;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 115),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Request", style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),

                  /// ✅ Worker: nombre real o Any
                  _workerLine(workerId),

                  if (days.isNotEmpty)
                    Text(
                      "• Day(s): ${days.map((d) => BookingRequestUtils.formatYyyyMmDdToDdMmYyyy(d.toString())).join(', ')}",
                    ),
                  if (ranges.isNotEmpty)
                    Text(
                      "• Range(s): ${ranges.map((r) {
                        final m = Map<String, dynamic>.from(r as Map);
                        return _formatRange(m);
                      }).join('; ')}",
                    ),
                  if (notes.isNotEmpty) Text("• Notes: $notes"),
                ],
              ),
            ),
            const SizedBox(width: 10),

            /// ✅ SIN STACK: botones nunca se superponen
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppIconPillButton(
                  icon: Icons.delete_outline,
                  color: Colors.redAccent,
                  shadow: false,
                  tooltip: "Delete request",
                  onTap: () async => onDelete(),
                ),
                AppIconPillButton(
                  icon: Icons.edit_outlined,
                  color: purple,
                  shadow: false,
                  tooltip: "Edit notes",
                  onTap: onEditNotes,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}