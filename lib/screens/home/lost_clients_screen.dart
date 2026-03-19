// lib/screens/home/lost_clients_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/components/client_card.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/screens/clients/clients_profile_screen.dart';
import 'package:salon_app/utils/date_time_utils.dart';

class LostClientsScreen extends StatefulWidget {
  const LostClientsScreen({super.key});

  @override
  State<LostClientsScreen> createState() => _LostClientsScreenState();
}

class _LostClientsScreenState extends State<LostClientsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppGradientHeader(
            title: s.lostClients,
            subtitle: s.clientsNoVisitRecently,
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xff721c80),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xff721c80),
              tabs: [
                Tab(
                  child: _TabLabel(
                    icon: Icons.warning_amber_rounded,
                    label: s.atRiskClients,
                    color: Colors.orange,
                  ),
                ),
                Tab(
                  child: _TabLabel(
                    icon: Icons.person_off_outlined,
                    label: s.lostClientsTab,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ClientBucketList(
                  minDays: 30,
                  maxDays: 45,
                  emptyMessage: '${s.noAtRiskClients} 🎉',
                  accentColor: Colors.orange,
                ),
                _ClientBucketList(
                  minDays: 45,
                  maxDays: null,
                  emptyMessage: '${s.noLostClients} 🎉',
                  accentColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bucket list ───────────────────────────────────────────────────────────────

class _ClientBucketList extends StatelessWidget {
  const _ClientBucketList({
    required this.minDays,
    required this.maxDays,
    required this.emptyMessage,
    required this.accentColor,
  });

  final int minDays;
  final int? maxDays;
  final String emptyMessage;
  final Color accentColor;

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final now       = DateTime.now();
    final cutoffMax = Timestamp.fromDate(now.subtract(Duration(days: minDays)));

    var q = FirebaseFirestore.instance
        .collection('clients')
        .where('stats.lastAppointmentAt', isLessThanOrEqualTo: cutoffMax)
        .orderBy('stats.lastAppointmentAt')
        .limit(200);

    if (maxDays != null) {
      final cutoffMin =
          Timestamp.fromDate(now.subtract(Duration(days: maxDays!)));
      q = q.where('stats.lastAppointmentAt', isGreaterThan: cutoffMin);
    }

    return q.snapshots();
  }

  String _daysSince(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate()).inDays;
    return '$diff days ago';
  }

  String _formatDate(Timestamp ts) {
    return DateTimeUtils.formatYyyyMmDdToDdMmYyyy(
        DateTimeUtils.yyyymmdd(ts.toDate()));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff721c80)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 56, color: Colors.green.shade300),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc    = docs[i];
            final data   = doc.data();
            final lastTs = data['stats']?['lastAppointmentAt'] as Timestamp?;
            final summary =
                (data['stats']?['lastAppointmentSummary'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClientCard(
                    data: data,
                    showChevron: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ClientProfileScreen(clientId: doc.id)),
                    ),
                    trailingBeforeChevron: lastTs != null
                        ? _DaysBadge(
                            label: _daysSince(lastTs),
                            color: accentColor,
                          )
                        : null,
                  ),
                  if (lastTs != null)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 12, top: 3, bottom: 2),
                      child: Text(
                        '${s.lastVisit}: ${_formatDate(lastTs)}'
                        '${summary.isNotEmpty ? "  ·  $summary" : ""}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
