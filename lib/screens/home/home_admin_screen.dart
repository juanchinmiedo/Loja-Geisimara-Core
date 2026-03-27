// lib/screens/home/home_admin_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/user_provider.dart';

import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';
import 'package:salon_app/components/ui/header_action_button.dart';

import 'package:salon_app/screens/home/lost_clients_screen.dart';
import 'package:salon_app/screens/clients/clients_profile_screen.dart';
import 'package:salon_app/widgets/admin_notifications_overlay.dart';

enum HomeAdminMode { looking, cancelled, noShow }

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  static const _purple = Color(0xff721c80);

  HomeAdminMode _mode = HomeAdminMode.looking;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _modeStream;

  HomeAdminMode get mode => _mode;

  void _setMode(HomeAdminMode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      _modeStream = _queryForMode().snapshots();
    });
  }

  @override
  void initState() {
    super.initState();
    _modeStream = _queryForMode().snapshots();
  }

  String _fullName(Map<String, dynamic> c, String fallback) {
    final fn   = (c['firstName'] ?? '').toString().trim();
    final ln   = (c['lastName']  ?? '').toString().trim();
    final name = '$fn $ln'.trim();
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

  Color _modeTint(HomeAdminMode m) {
    switch (m) {
      case HomeAdminMode.looking:   return _purple;
      case HomeAdminMode.cancelled: return Colors.orange;
      case HomeAdminMode.noShow:    return Colors.redAccent;
    }
  }

  IconData _modeIcon(HomeAdminMode m) {
    switch (m) {
      case HomeAdminMode.looking:   return Icons.notifications_active_outlined;
      case HomeAdminMode.cancelled: return Icons.event_busy_rounded;
      case HomeAdminMode.noShow:    return Icons.person_off_rounded;
    }
  }

  // ── Header child: fecha + 3 stat pills reactivas al modo ─────────────────────
  Widget _buildHeaderChild(S s) {
    final now     = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM', Localizations.localeOf(context).toString()).format(now);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('clients').snapshots(),
      builder: (_, snap) {
        final docs      = snap.data?.docs ?? [];
        final looking   = docs.where((d) => d.data()['bookingRequestActive'] == true).length;
        final cancelled = docs.where((d) => (((d.data()['stats']?['totalCancelled']) as num?)?.toInt() ?? 0) > 0).length;
        final noShow    = docs.where((d) => (((d.data()['stats']?['totalNoShow'])    as num?)?.toInt() ?? 0) > 0).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fecha + campana — misma fila, igual que buscador + botón en clients
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildBellButton(),
              ],
            ),
            const SizedBox(height: 10),
            // 3 pills — mismo estilo que clients, color del modo activo resaltado
            Row(
              children: [
                _statPill(
                  icon: Icons.notifications_active_outlined,
                  value: '$looking',
                  color: Colors.white,
                  active: mode == HomeAdminMode.looking,
                  activeColor: Colors.white,
                ),
                const SizedBox(width: 8),
                _statPill(
                  icon: Icons.event_busy_rounded,
                  value: '$cancelled',
                  color: Colors.white,
                  active: mode == HomeAdminMode.cancelled,
                  activeColor: Colors.orange[300]!,
                ),
                const SizedBox(width: 8),
                _statPill(
                  icon: Icons.person_off_rounded,
                  value: '$noShow',
                  color: Colors.white,
                  active: mode == HomeAdminMode.noShow,
                  activeColor: Colors.red[300]!,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statPill({
    required IconData icon,
    required String value,
    required Color color,
    bool active = false,
    Color? activeColor,
  }) {
    final c = active ? (activeColor ?? color) : color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(active ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(active ? 0.55 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c.withOpacity(active ? 1.0 : 0.75)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: c.withOpacity(active ? 1.0 : 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bell button ───────────────────────────────────────────────────────────────
  Widget _buildBellButton() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('clients')
          .doc('__system__')
          .collection('history')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapA) {
        final count = snapA.data?.docs.length ?? 0;
        return HeaderActionButton(
          icon: Icons.notifications_active_outlined,
          badgeCount: count,
          onTap: () => AdminNotificationsOverlay.show(
            context,
            onOpenClient: (clientId) =>
                context.read<AdminNavProvider>().goToClientsAndOpen(clientId),
          ),
        );
      },
    );
  }

  // ── Mode buttons (bottom panel) ───────────────────────────────────────────────
  Widget _modeButtons(bool isAdmin, S s) {
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
                color: active
                    ? tint.withOpacity(0.55)
                    : Colors.black.withOpacity(0.18),
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
                        fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            pill(
              active: mode == HomeAdminMode.looking,
              onTap: () => _setMode(HomeAdminMode.looking),
              icon: Icons.notifications_active_outlined,
              label: s.modeLooking,
              tint: _purple,
              iconColor: _purple,
            ),
            const SizedBox(width: 10),
            pill(
              active: mode == HomeAdminMode.cancelled,
              onTap: () => _setMode(HomeAdminMode.cancelled),
              icon: Icons.event_busy_rounded,
              label: s.modeCancelled,
              tint: Colors.orange,
              iconColor: Colors.orange[800] ?? Colors.orange,
            ),
            const SizedBox(width: 10),
            pill(
              active: mode == HomeAdminMode.noShow,
              onTap: () => _setMode(HomeAdminMode.noShow),
              icon: Icons.person_off_rounded,
              label: s.modeNoShow,
              tint: Colors.redAccent,
              iconColor: Colors.redAccent,
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LostClientsScreen()),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.brown.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined, size: 18, color: Colors.brown[600]),
                    const SizedBox(width: 8),
                    Text(
                      s.lostClientsButton,
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.brown[700]),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 18, color: Colors.brown[400]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openClientProfile(String clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientProfileScreen(clientId: clientId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s            = S.of(context);
    final stream       = _modeStream ?? _queryForMode().snapshots();
    final isAdmin      = context.watch<UserProvider>().isAdmin;
    final bottomPanelH = isAdmin ? 140.0 : 92.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPanelH + 18),
              child: Column(
                children: [
                  AppGradientHeader(
                    title: s.adminHome,
                    height: 195,
                    child: _buildHeaderChild(s),
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
                          return Text('Error: ${snap.error}',
                              style: const TextStyle(color: Colors.red));
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return AppSectionCard(
                            title: s.results,
                            child: Text(
                              mode == HomeAdminMode.looking
                                  ? s.noActiveBookingRequests
                                  : s.noClientsMatchFilter,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((d) {
                            final c           = d.data();
                            final clientId    = d.id;
                            final displayName = _fullName(c, clientId);
                            final contact     = _contactLine(c);
                            final cancelled   = ((c['stats']?['totalCancelled']) as num?)?.toInt() ?? 0;
                            final noShow      = ((c['stats']?['totalNoShow'])    as num?)?.toInt() ?? 0;
                            final attended    = ((c['stats']?['totalScheduled']) as num?)?.toInt() ?? 0;
                            final tint        = _modeTint(mode);

                            Widget trailingWidget() {
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
                                  child: Text('×$cancelled',
                                      style: const TextStyle(fontWeight: FontWeight.w900)),
                                );
                              }
                              return AppPill(
                                background: Colors.redAccent.withOpacity(0.12),
                                borderColor: Colors.redAccent.withOpacity(0.28),
                                child: Text('×$noShow',
                                    style: const TextStyle(fontWeight: FontWeight.w900)),
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _openClientProfile(clientId),
                                borderRadius: BorderRadius.circular(14),
                                child: AppSectionCard(
                                  title: displayName,
                                  trailing: trailingWidget(),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (contact.isNotEmpty)
                                        Text(contact,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[700])),
                                      const SizedBox(height: 6),
                                      if (mode == HomeAdminMode.looking)
                                        Text(s.tapToViewProfile)
                                      else
                                        Text('${s.attended}: $attended',
                                            style: TextStyle(color: Colors.grey[700])),
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

          // Panel sticky inferior
          Positioned(
            left: 0, right: 0, bottom: 0,
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
                child: _modeButtons(isAdmin, s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
