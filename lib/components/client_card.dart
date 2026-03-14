// lib/components/client_card.dart
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
    // Nuevo: pill con próximo turno bajo la línea de contacto
    this.nextAppointmentLabel,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool seeking;
  final Widget? trailingBeforeChevron;
  final ClientCardVariant variant;

  /// Cuando no es null muestra una pill morada con icono de calendario.
  /// Pasar null mantiene el comportamiento anterior exactamente igual.
  final String? nextAppointmentLabel;

  String _s(String k) => (data[k] ?? '').toString();
  int _i(String k) => data[k] is num ? (data[k] as num).toInt() : 0;

  String _fullName() {
    final v = '${_s('firstName')} ${_s('lastName')}'.trim();
    return v.isEmpty ? 'Client' : v;
  }

  String _contactLine() {
    final c = _i('country');
    final p = _i('phone');
    final ig = _s('instagram');
    final parts = <String>[];
    if (c > 0 && p > 0) parts.add('+$c $p');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName();
    final contact = _contactLine();

    final isHighlighted = variant == ClientCardVariant.selected ||
        variant == ClientCardVariant.popup;

    final bg = isHighlighted
        ? const Color(0xff721c80).withOpacity(0.08)
        : Colors.grey.withOpacity(0.06);
    final border =
        isHighlighted ? const Color(0xff721c80).withOpacity(0.20) : Colors.black12;

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
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    // Próximo turno pill
                    if (nextAppointmentLabel != null) ...[
                      const SizedBox(height: 5),
                      _NextApptPill(label: nextAppointmentLabel!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailingBeforeChevron != null) ...[
                trailingBeforeChevron!,
                const SizedBox(width: 10),
              ] else if (seeking) ...[
                _SeekingBadge(),
                const SizedBox(width: 10),
              ],
              if (showChevron)
                const Icon(Icons.chevron_right_rounded,
                    size: 28, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  static bool isSeeking(Map<String, dynamic> data) =>
      data['seekingAppointment'] == true;

  static List<Timestamp> seekingSlots(Map<String, dynamic> data) {
    final raw = data['seekingSlots'];
    if (raw is List) return raw.whereType<Timestamp>().toList();
    return const [];
  }
}

class _NextApptPill extends StatelessWidget {
  const _NextApptPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff721c80).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xff721c80).withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 11, color: Color(0xff721c80)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xff721c80),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeekingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          Icon(Icons.notifications_active_outlined,
              size: 16, color: Colors.black87),
          SizedBox(width: 6),
          Text('Seeking',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}

enum ClientCardVariant { compact, selected, popup }
