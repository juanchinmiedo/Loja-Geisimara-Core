import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';

class HomeAdminScreen extends StatelessWidget {
  const HomeAdminScreen({super.key});

  bool _isLooking(Map<String, dynamic> data) {
    final br = data['bookingRequest'];
    if (br is Map<String, dynamic>) {
      return br['active'] == true;
    }
    return false;
  }

  String _fullName(Map<String, dynamic> data) {
    final fn = (data['firstName'] ?? '').toString().trim();
    final ln = (data['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    return name.isEmpty ? 'Client' : name;
  }

  String _contactLine(Map<String, dynamic> data) {
    final ctry = (data['country'] is num) ? (data['country'] as num).toInt() : 0;
    final ph = (data['phone'] is num) ? (data['phone'] as num).toInt() : 0;
    final ig = (data['instagram'] ?? '').toString().trim();

    final parts = <String>[];
    if (ctry > 0 && ph > 0) parts.add('+$ctry $ph');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  Widget _clientCard({
    required BuildContext context,
    required String clientId,
    required Map<String, dynamic> data,
    required VoidCallback onOpen,
  }) {
    final s = S.of(context);
    final isLooking = _isLooking(data);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xff721c80).withOpacity(0.15)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Dot / status
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isLooking ? const Color(0xff721c80) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName(data),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _contactLine(data).isEmpty ? s.clientFallback : _contactLine(data),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Looking badge BEFORE >
            if (isLooking) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff721c80).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xff721c80).withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: Color(0xff721c80),
                ),
              ),
              const SizedBox(width: 8),
            ],

            IconButton(
              onPressed: onOpen,
              icon: const Icon(Icons.chevron_right, size: 28),
              color: Colors.black54,
              tooltip: "Open",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    // ✅ HomeAdmin: clientes con bookingRequest.active = true
    final stream = FirebaseFirestore.instance
        .collection('clients')
        .where('bookingRequest.active', isEqualTo: true)
        .orderBy('bookingRequest.updatedAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header (igual vibe que tu app)
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff721c80), Color.fromARGB(255, 196, 103, 169)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 46, left: 18, right: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Admin Home",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Clients looking for appointments",
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator(color: Colors.purple)),
                    );
                  }
                  if (snap.hasError) {
                    return Text("Error: ${snap.error}", style: const TextStyle(color: Colors.red));
                  }

                  final docs = snap.data?.docs ?? [];
                  final count = docs.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alert card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff721c80).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xff721c80).withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xff721c80)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                count == 0
                                    ? "No clients are looking for appointments right now."
                                    : "$count client(s) are looking for an appointment.",
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (docs.isEmpty)
                        Text(
                          "Nothing to show.",
                          style: TextStyle(color: Colors.grey[700]),
                        ),

                      if (docs.isNotEmpty)
                        ...docs.map((d) {
                          final data = d.data();
                          return _clientCard(
                            context: context,
                            clientId: d.id,
                            data: data,
                            onOpen: () => context.read<AdminNavProvider>().goToClientsAndOpen(d.id),
                          );
                        }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
