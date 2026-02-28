import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

enum BookingRequestAvailability { available, unavailable, unknown }

/// Reusable compact card for a single booking request.
/// - Worker shows REAL name if possible (or Any if null).
/// - Shows a Google-like availability pill (green/red/grey).
class BookingRequestCard extends StatelessWidget {
  const BookingRequestCard({
    super.key,
    required this.requestId,
    required this.br,
    required this.purple,
    required this.onDelete,
    required this.onEditRequest,
    this.availability = BookingRequestAvailability.unknown,
    this.availabilityLabel,
  });

  final String requestId;
  final Map<String, dynamic> br;
  final Color purple;
  final Future<void> Function() onDelete;
  final VoidCallback onEditRequest;

  final BookingRequestAvailability availability;
  final String? availabilityLabel;

  String _formatRange(Map<String, dynamic> r) {
    final s = (r['startMin'] ?? r['start']);
    final e = (r['endMin'] ?? r['end']);
    final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? 0;
    final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? 0;

    String hm(int m) =>
        "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";
    return "${hm(sm)} - ${hm(em)}";
  }

  Widget _availabilityPill() {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (availability) {
      case BookingRequestAvailability.available:
        bg = const Color(0xFFE6F4EA);
        border = const Color(0xFF34A853);
        text = const Color(0xFF137333);
        label = (availabilityLabel ?? '').trim();
        if (label.isEmpty) label = ' '; // mantiene tamaño
        break;

      case BookingRequestAvailability.unavailable:
        bg = const Color(0xFFFCE8E6);
        border = const Color(0xFFEA4335);
        text = const Color(0xFFA50E0E);
        label = (availabilityLabel ?? 'No availability').trim();
        if (label.isEmpty) label = 'No availability';
        break;

      case BookingRequestAvailability.unknown:
        bg = Colors.black.withOpacity(0.05);
        border = Colors.black.withOpacity(0.12);
        text = Colors.black.withOpacity(0.70);
        label = (availabilityLabel ?? 'Checking…').trim();
        if (label.isEmpty) label = 'Checking…';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: text),
      ),
    );
  }

  Widget _workerLine(String? workerId) {
    if (workerId == null || workerId.trim().isEmpty) {
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
        return Text("• Worker: $workerId");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = (br['preferredDays'] as List?) ?? const [];
    final ranges = (br['preferredTimeRanges'] as List?) ?? const [];
    final proc = (br['serviceNameLabel'] ?? br['serviceNameKey'] ?? '').toString().trim();
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text("Request", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      _availabilityPill(),
                    ],
                  ),
                  const SizedBox(height: 6),

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

                  if (proc.isNotEmpty) Text("• Procedure: $proc"),
                ],
              ),
            ),
            const SizedBox(width: 10),
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
                  tooltip: "Edit request",
                  onTap: onEditRequest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}