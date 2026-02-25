import 'package:flutter/material.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

class BookingRequestCard extends StatelessWidget {
  const BookingRequestCard({
    super.key,
    required this.data,
    required this.onDelete,
    required this.onEditNotes,
    this.purple = const Color(0xff721c80),
  });

  final Map<String, dynamic> data;
  final Future<void> Function() onDelete;
  final Future<void> Function() onEditNotes;
  final Color purple;

  String _formatRange(Map<String, dynamic> r) {
    final s = (r['startMin'] as num?)?.toInt() ?? 0;
    final e = (r['endMin'] as num?)?.toInt() ?? 0;
    String hm(int m) =>
        "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";
    return "${hm(s)} - ${hm(e)}";
  }

  @override
  Widget build(BuildContext context) {
    final days = (data['preferredDays'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final ranges = (data['preferredTimeRanges'] as List?) ?? const [];
    final notes = (data['notes'] ?? '').toString().trim();
    final workerId = data['workerId'] as String?; // null => Any

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Request", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),

                Text("• Worker: ${workerId ?? "Any"}"),

                if (days.isNotEmpty)
                  Text(
                    "• Day(s): ${days.map((d) => BookingRequestUtils.formatYyyyMmDdToDdMmYyyy(d)).join(', ')}",
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

          // Botón delete (arriba derecha)
          Positioned(
            top: 0,
            right: 0,
            child: AppIconPillButton(
              icon: Icons.delete_outline,
              color: Colors.redAccent,
              shadow: false,
              tooltip: "Delete request",
              onTap: () => onDelete(),
            ),
          ),

          // Botón edit (abajo derecha)
          Positioned(
            bottom: 0,
            right: 0,
            child: AppIconPillButton(
              icon: Icons.edit_outlined,
              color: purple,
              shadow: false,
              tooltip: "Edit notes",
              onTap: () => onEditNotes(),
            ),
          ),
        ],
      ),
    );
  }
}