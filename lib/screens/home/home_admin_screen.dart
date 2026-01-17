import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';

enum _HomeAdminMode { looking, cancelled, noShow }

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  _HomeAdminMode mode = _HomeAdminMode.looking;

  String _fullName(Map<String, dynamic> c, String fallback) {
    final fn = (c['firstName'] ?? '').toString().trim();
    final ln = (c['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    return name.isEmpty ? fallback : name;
  }

  String _contactLine(Map<String, dynamic> c) {
    final ctry = (c['country'] is num)
        ? (c['country'] as num).toInt()
        : int.tryParse('${c['country'] ?? ''}') ?? 0;

    final ph = (c['phone'] is num)
        ? (c['phone'] as num).toInt()
        : int.tryParse('${c['phone'] ?? ''}') ?? 0;

    final ig = (c['instagram'] ?? '').toString().trim();

    final parts = <String>[];
    if (ctry > 0 && ph > 0) parts.add('+$ctry $ph');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  Query<Map<String, dynamic>> _queryForMode() {
    final col = FirebaseFirestore.instance.collection('clients');

    switch (mode) {
      case _HomeAdminMode.looking:
        return col
            .where('bookingRequestActive', isEqualTo: true)
            .orderBy('bookingRequestUpdatedAt', descending: true)
            .limit(80);

      case _HomeAdminMode.cancelled:
        return col
            .where('stats.totalCancelled', isGreaterThan: 0)
            .orderBy('stats.totalCancelled', descending: true)
            .orderBy('stats.totalScheduled', descending: true)
            .limit(80);

      case _HomeAdminMode.noShow:
        return col
            .where('stats.totalNoShow', isGreaterThan: 0)
            .orderBy('stats.totalNoShow', descending: true)
            .orderBy('stats.totalScheduled', descending: true)
            .limit(80);
    }
  }

  String _subtitle() {
    switch (mode) {
      case _HomeAdminMode.looking:
        return "Clients looking for appointments";
      case _HomeAdminMode.cancelled:
        return "Most cancellations (then most attended)";
      case _HomeAdminMode.noShow:
        return "Most no-shows (then most attended)";
    }
  }

  Widget _modeButtonsRow() {
    const purple = Color(0xff721c80);

    Widget pillButton({
      required bool active,
      required VoidCallback onTap,
      required IconData icon,
      required String label,
      required Color tint,
      required Color iconColor,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: active ? tint.withOpacity(0.18) : tint.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.black.withOpacity(active ? 0.22 : 0.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pillButton(
          active: mode == _HomeAdminMode.looking,
          onTap: () => setState(() => mode = _HomeAdminMode.looking),
          icon: Icons.notifications_active_outlined,
          label: "Looking",
          tint: purple,
          iconColor: purple,
        ),
        const SizedBox(width: 10),
        pillButton(
          active: mode == _HomeAdminMode.cancelled,
          onTap: () => setState(() => mode = _HomeAdminMode.cancelled),
          icon: Icons.event_busy_rounded,
          label: "Cancelled",
          tint: Colors.orange,
          iconColor: Colors.orange[800] ?? Colors.orange,
        ),
        const SizedBox(width: 10),
        pillButton(
          active: mode == _HomeAdminMode.noShow,
          onTap: () => setState(() => mode = _HomeAdminMode.noShow),
          icon: Icons.person_off_rounded,
          label: "No-show",
          tint: Colors.redAccent,
          iconColor: Colors.redAccent,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _queryForMode().snapshots();

    // altura reservada para que la lista no quede debajo del panel fijo
    const fixedBottomPanelHeight = 92.0;

    return Scaffold(
      body: Stack(
        children: [
          // ───────────── LISTA SCROLLEABLE ─────────────
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: fixedBottomPanelHeight + 18),
              child: Column(
                children: [
                  AppGradientHeader(
                    title: "Admin Home",
                    subtitle: _subtitle(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: stream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Text(
                            "Error: ${snap.error}",
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return AppSectionCard(
                            title: "Results",
                            child: Text(
                              mode == _HomeAdminMode.looking
                                  ? "No active booking requests right now."
                                  : "No clients match this filter.",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((d) {
                            final c = d.data();
                            final clientId = d.id;

                            final displayName = _fullName(c, clientId);
                            final contact = _contactLine(c);

                            final cancelled = ((c['stats']?['totalCancelled']) as num?)?.toInt() ?? 0;
                            final noShow = ((c['stats']?['totalNoShow']) as num?)?.toInt() ?? 0;

                            // OJO: aquí mostramos attended = totalDone (si lo tienes),
                            // y si no existe, caemos a totalScheduled como fallback.
                            final attended = ((c['stats']?['totalDone']) as num?)?.toInt() ??
                                (((c['stats']?['totalScheduled']) as num?)?.toInt() ?? 0);

                            Widget trailing() {
                              const purple = Color(0xff721c80);

                              if (mode == _HomeAdminMode.looking) {
                                return AppPill(
                                  background: purple.withOpacity(0.10),
                                  borderColor: purple.withOpacity(0.25),
                                  child: const Icon(
                                    Icons.notifications_active_outlined,
                                    size: 16,
                                    color: purple,
                                  ),
                                );
                              }

                              if (mode == _HomeAdminMode.cancelled) {
                                return AppPill(
                                  background: Colors.orange.withOpacity(0.12),
                                  borderColor: Colors.orange.withOpacity(0.28),
                                  child: Text(
                                    "×$cancelled",
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                );
                              }

                              return AppPill(
                                background: Colors.redAccent.withOpacity(0.12),
                                borderColor: Colors.redAccent.withOpacity(0.28),
                                child: Text(
                                  "×$noShow",
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => context.read<AdminNavProvider>().goToClientsAndOpen(clientId),
                                borderRadius: BorderRadius.circular(14),
                                child: AppSectionCard(
                                  title: displayName,
                                  trailing: trailing(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (contact.isNotEmpty)
                                        Text(
                                          contact,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      const SizedBox(height: 6),
                                      if (mode == _HomeAdminMode.looking)
                                        const Text(
                                          "Tap to view request details",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      else
                                        Text(
                                          "Attended: $attended",
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ───────────── PANEL FIJO ABAJO ─────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButtonsRow(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
