import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';

class HomeAdminScreen extends StatelessWidget {
  const HomeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('booking_requests')
        .where('active', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AppGradientHeader(
              title: "Admin Home",
              subtitle: "Clients looking for appointments",
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
                    return Text("Error: ${snap.error}", style: const TextStyle(color: Colors.red));
                  }

                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return AppSectionCard(
                      title: "Alerts",
                      child: Text("No active booking requests right now.", style: TextStyle(color: Colors.grey[700])),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final br = d.data();
                      final clientId = (br['clientId'] ?? '').toString();

                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('clients').doc(clientId).get(),
                        builder: (context, csnap) {
                          final c = csnap.data?.data() ?? {};
                          final name = "${(c['firstName'] ?? '').toString().trim()} ${(c['lastName'] ?? '').toString().trim()}".trim();
                          final displayName = name.isEmpty ? clientId : name;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => context.read<AdminNavProvider>().goToClientsAndOpen(clientId),
                              borderRadius: BorderRadius.circular(14),
                              child: AppSectionCard(
                                title: displayName,
                                trailing: AppPill(
                                  background: const Color(0xff721c80).withOpacity(0.10),
                                  borderColor: const Color(0xff721c80).withOpacity(0.25),
                                  child: const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xff721c80)),
                                ),
                                child: Text(
                                  (br['notes'] ?? '').toString().isEmpty ? "Open to see request details" : "Notes: ${br['notes']}",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
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
