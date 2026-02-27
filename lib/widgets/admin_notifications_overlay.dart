import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lock-screen style notifications overlay for Admin.
/// - Slides in from the right
/// - Each item is Dismissible (swipe right) to delete the notification
/// - Tap an item to "open" a client if clientId is present
class AdminNotificationsOverlay extends StatelessWidget {
  const AdminNotificationsOverlay({
    super.key,
    required this.onOpenClient,
  });

  final void Function(String clientId) onOpenClient;

  static Future<void> show(
    BuildContext context, {
    required void Function(String clientId) onOpenClient,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: AdminNotificationsOverlay(onOpenClient: onOpenClient),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, __, child) {
        final tween = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: anim.drive(tween), child: child);
      },
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final q = db
        .collection('clients')
        .doc('_system')
        .collection('history')
        .where('createdAt', isGreaterThan: Timestamp(0, 0))
        .orderBy('createdAt', descending: true)
        .limit(60);

    final width = MediaQuery.of(context).size.width;
    final panelW = (width * 0.88).clamp(300.0, 420.0);

    return Container(
      width: panelW,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(-8, 0),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: Color(0xff721c80)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No notifications.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();

                    final title = (data['title'] ?? 'Notification').toString();
                    final body = (data['body'] ?? '').toString();
                    final type = (data['type'] ?? '').toString();
                    final clientId = (data['clientId'] ?? '').toString();
                    final ts = data['createdAt'];
                    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

                    IconData icon;
                    Color tint;
                    switch (type) {
                      case 'booking_request_expired_deleted':
                        icon = Icons.timer_off_outlined;
                        tint = Colors.redAccent;
                        break;
                      case 'booking_request_removed_by_appointment':
                        icon = Icons.event_available_rounded;
                        tint = const Color(0xff721c80);
                        break;
                      case 'freed_slot_matches':
                        icon = Icons.auto_awesome_rounded;
                        tint = Colors.green;
                        break;
                      default:
                        icon = Icons.notifications_none_rounded;
                        tint = Colors.blueGrey;
                    }

                    return Dismissible(
                      key: ValueKey(d.id),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.22)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Dismiss',
                                style: TextStyle(
                                    color: Colors.red, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      onDismissed: (_) async {
                        await d.reference.delete();
                      },
                      child: InkWell(
                        onTap: clientId.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context);
                                onOpenClient(clientId);
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tint.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: tint.withOpacity(0.22)),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tint.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: tint),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _ago(createdAt),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (body.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        body,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[800]),
                                      ),
                                    ],
                                    if (clientId.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to open client',
                                        style: TextStyle(
                                          color: tint,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
