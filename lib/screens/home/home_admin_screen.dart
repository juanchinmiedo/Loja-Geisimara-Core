import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';

import 'package:salon_app/screens/home/home_client_bottom_sheet.dart';
import 'package:salon_app/widgets/admin_notifications_overlay.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  HomeAdminMode mode = HomeAdminMode.looking;

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
      case HomeAdminMode.looking:
        return col
            .where('bookingRequestActive', isEqualTo: true)
            .orderBy('bookingRequestUpdatedAt', descending: true)
            .limit(80);

      case HomeAdminMode.cancelled:
        return col
            .where('stats.totalCancelled', isGreaterThan: 0)
            .orderBy('stats.totalCancelled', descending: true)
            .orderBy('stats.totalScheduled', descending: true)
            .limit(80);

      case HomeAdminMode.noShow:
        return col
            .where('stats.totalNoShow', isGreaterThan: 0)
            .orderBy('stats.totalNoShow', descending: true)
            .orderBy('stats.totalScheduled', descending: true)
            .limit(80);
    }
  }

  String _subtitle() {
    switch (mode) {
      case HomeAdminMode.looking:
        return "Clients looking for appointments";
      case HomeAdminMode.cancelled:
        return "Most cancellations (then most attended)";
      case HomeAdminMode.noShow:
        return "Most no-shows (then most attended)";
    }
  }

  Color _modeTint(HomeAdminMode m) {
    switch (m) {
      case HomeAdminMode.looking:
        return const Color(0xff721c80);
      case HomeAdminMode.cancelled:
        return Colors.orange;
      case HomeAdminMode.noShow:
        return Colors.redAccent;
    }
  }

  IconData _modeIcon(HomeAdminMode m) {
    switch (m) {
      case HomeAdminMode.looking:
        return Icons.notifications_active_outlined;
      case HomeAdminMode.cancelled:
        return Icons.event_busy_rounded;
      case HomeAdminMode.noShow:
        return Icons.person_off_rounded;
    }
  }

  Widget _modeButtons() {
    const purple = Color(0xff721c80);

    Widget pill({
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
              color: active ? tint.withOpacity(0.22) : tint.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? tint.withOpacity(0.55) : Colors.black.withOpacity(0.18),
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
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
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
        pill(
          active: mode == HomeAdminMode.looking,
          onTap: () => setState(() => mode = HomeAdminMode.looking),
          icon: Icons.notifications_active_outlined,
          label: "Looking",
          tint: purple,
          iconColor: purple,
        ),
        const SizedBox(width: 10),
        pill(
          active: mode == HomeAdminMode.cancelled,
          onTap: () => setState(() => mode = HomeAdminMode.cancelled),
          icon: Icons.event_busy_rounded,
          label: "Cancelled",
          tint: Colors.orange,
          iconColor: Colors.orange[800] ?? Colors.orange,
        ),
        const SizedBox(width: 10),
        pill(
          active: mode == HomeAdminMode.noShow,
          onTap: () => setState(() => mode = HomeAdminMode.noShow),
          icon: Icons.person_off_rounded,
          label: "No-show",
          tint: Colors.redAccent,
          iconColor: Colors.redAccent,
        ),
      ],
    );
  }

  Future<void> _openClientSheet(String clientId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => HomeClientBottomSheet(
        clientId: clientId,
        mode: mode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _queryForMode().snapshots();

    const fixedBottomPanelHeight = 92.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: fixedBottomPanelHeight + 18),
              child: Column(
                children: [
                  AppGradientHeader(
                    title: "Admin Home",
                    subtitle: _subtitle(),
                  ),
                  // (contenido sigue...)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: stream,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Text("Error: ${snap.error}", style: const TextStyle(color: Colors.red));
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return AppSectionCard(
                            title: "Results",
                            child: Text(
                              mode == HomeAdminMode.looking
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
                            final attended = ((c['stats']?['totalScheduled']) as num?)?.toInt() ?? 0;

                            final tint = _modeTint(mode);

                            Widget trailing() {
                              if (mode == HomeAdminMode.looking) {
                                return AppPill(
                                  background: tint.withOpacity(0.10),
                                  borderColor: tint.withOpacity(0.25),
                                  child: Icon(_modeIcon(mode), size: 16, color: tint),
                                );
                              }
                              if (mode == HomeAdminMode.cancelled) {
                                return AppPill(
                                  background: Colors.orange.withOpacity(0.12),
                                  borderColor: Colors.orange.withOpacity(0.28),
                                  child: Text("×$cancelled", style: const TextStyle(fontWeight: FontWeight.w900)),
                                );
                              }
                              return AppPill(
                                background: Colors.redAccent.withOpacity(0.12),
                                borderColor: Colors.redAccent.withOpacity(0.28),
                                child: Text("×$noShow", style: const TextStyle(fontWeight: FontWeight.w900)),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _openClientSheet(clientId),
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
                                      if (mode == HomeAdminMode.looking)
                                        const Text("Tap to view request details")
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

          // ✅ Campana + badge en HOME (no en Clients)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 10,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('clients')
                  .doc('__system__')
                  .collection('history')
                  .orderBy('createdAt', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapA) {
                final count = (snapA.data?.docs.length ?? 0);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AdminNotificationsOverlay.show(
                        context,
                        onOpenClient: (clientId) {
                          // ✅ ir a Clients y abrir perfil
                          context.read<AdminNavProvider>().goToClientsAndOpen(clientId);
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.25)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xff721c80),
                              size: 22,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                child: _modeButtons(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}