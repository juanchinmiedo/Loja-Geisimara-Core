import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.data,
    this.onTap,
    this.showChevron = false,
    this.seeking = false,
    this.trailingBeforeChevron,
    this.variant = ClientCardVariant.compact,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  /// si quieres el ">" al final
  final bool showChevron;

  /// si este cliente está buscando cita (badge)
  final bool seeking;

  /// algo a la derecha ANTES del ">" (por ejemplo el badge)
  final Widget? trailingBeforeChevron;

  /// estilo
  final ClientCardVariant variant;

  String _s(String k) => (data[k] ?? '').toString();

  int _i(String k) => (data[k] is num) ? (data[k] as num).toInt() : 0;

  String _fullName() {
    final fn = _s('firstName');
    final ln = _s('lastName');
    final v = "$fn $ln".trim();
    return v.isEmpty ? "Client" : v;
  }

  String _contactLine() {
    final c = _i('country');
    final p = _i('phone');
    final ig = _s('instagram');

    final parts = <String>[];
    if (c > 0 && p > 0) parts.add("+$c $p");
    if (ig.isNotEmpty) parts.add("@$ig");
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName();
    final contact = _contactLine();

    // ✅ colores: mismo look que tu "selected client" morado clarito
    final bg = (variant == ClientCardVariant.selected || variant == ClientCardVariant.popup)
        ? const Color(0xff721c80).withOpacity(0.08)
        : Colors.grey.withOpacity(0.06);

    final border = (variant == ClientCardVariant.selected || variant == ClientCardVariant.popup)
        ? const Color(0xff721c80).withOpacity(0.20)
        : Colors.black12;

    final nameColor = Colors.black87;
    final subColor = Colors.grey[700];

    Widget badgeSeeking() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.amber.withOpacity(0.45)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_outlined, size: 16, color: Colors.black87),
            SizedBox(width: 6),
            Text(
              "Seeking",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, color: nameColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ✅ a la derecha antes del ">"
                if (trailingBeforeChevron != null) ...[
                  trailingBeforeChevron!,
                  const SizedBox(width: 10),
                ] else if (seeking) ...[
                  badgeSeeking(),
                  const SizedBox(width: 10),
                ],

                if (showChevron)
                  const Icon(Icons.chevron_right_rounded, size: 28, color: Colors.black45),
              ],
            ),
          ),
        ),
    );
  }

  /// helpers
  static bool isSeeking(Map<String, dynamic> data) => data['seekingAppointment'] == true;

  static List<Timestamp> seekingSlots(Map<String, dynamic> data) {
    final raw = data['seekingSlots'];
    if (raw is List) {
      return raw.whereType<Timestamp>().toList();
    }
    return const [];
  }
}

enum ClientCardVariant { compact, selected, popup }