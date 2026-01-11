import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';

class ClientsAdminScreen extends StatefulWidget {
  const ClientsAdminScreen({super.key});

  @override
  State<ClientsAdminScreen> createState() => _ClientsAdminScreenState();
}

class _ClientsAdminScreenState extends State<ClientsAdminScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isLooking(Map<String, dynamic> data) {
    final br = data['bookingRequest'];
    if (br is Map<String, dynamic>) return br['active'] == true;
    return false;
  }

  String _fullName(Map<String, dynamic> data, String fallback) {
    final fn = (data['firstName'] ?? '').toString().trim();
    final ln = (data['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    return name.isEmpty ? fallback : name;
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
                    _fullName(data, s.clientFallback),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openClientBottomSheet(BuildContext context, String clientId) async {
    final s = S.of(context);

    final snap = await FirebaseFirestore.instance.collection('clients').doc(clientId).get();
    final data = snap.data() ?? {};

    final nameCtrl = TextEditingController(text: _fullName(data, s.clientFallback));
    final fnCtrl = TextEditingController(text: (data['firstName'] ?? '').toString());
    final lnCtrl = TextEditingController(text: (data['lastName'] ?? '').toString());
    final countryCtrl = TextEditingController(text: (data['country'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (data['phone'] ?? '').toString());
    final igCtrl = TextEditingController(text: (data['instagram'] ?? '').toString());

    final looking = _isLooking(data);
    final br = (data['bookingRequest'] is Map<String, dynamic>) ? (data['bookingRequest'] as Map<String, dynamic>) : {};
    final notesCtrl = TextEditingController(text: (br['notes'] ?? '').toString());

    Future<void> setLooking(bool active) async {
      await FirebaseFirestore.instance.collection('clients').doc(clientId).set({
        'bookingRequest': {
          'active': active,
          'notes': notesCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    Future<void> saveEdits() async {
      final ctry = int.tryParse(countryCtrl.text.trim()) ?? 0;
      final ph = int.tryParse(phoneCtrl.text.trim()) ?? 0;

      await FirebaseFirestore.instance.collection('clients').doc(clientId).set({
        'firstName': fnCtrl.text.trim(),
        'lastName': lnCtrl.text.trim(),
        'country': ctry,
        'phone': ph,
        'instagram': igCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        // No tocamos search/createdAt aquí (si ya existen, se quedan).
      }, SetOptions(merge: true));
    }

    Future<void> deleteClient() async {
      await FirebaseFirestore.instance.collection('clients').doc(clientId).delete();
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        final bottomInset = MediaQuery.of(_).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 16 + bottomInset),
          child: StatefulBuilder(
            builder: (ctx, setStateSheet) {
              bool isLookingLocal = looking;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fullName(data, s.clientFallback),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLookingLocal)
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
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Preview card (igual estilo al “selected client”)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xff721c80).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff721c80).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName(data, s.clientFallback),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _contactLine(data),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Looking section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Booking request",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isLookingLocal ? "Looking for appointment" : "Not looking",
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Switch(
                                value: isLookingLocal,
                                activeColor: const Color(0xff721c80),
                                onChanged: (v) async {
                                  setStateSheet(() => isLookingLocal = v);
                                  await setLooking(v);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          TextField(
                            controller: notesCtrl,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Notes / preferences",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              // guardamos cuando tocas botones (no auto-save)
                            },
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // aseguro merge de notes también
                                await FirebaseFirestore.instance.collection('clients').doc(clientId).set({
                                  'bookingRequest': {
                                    'active': isLookingLocal,
                                    'notes': notesCtrl.text.trim(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  },
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text("Booking request saved")),
                                );
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text("Save booking request"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Edit section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Client data", style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: fnCtrl,
                            decoration: const InputDecoration(labelText: "First name", border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: lnCtrl,
                            decoration: const InputDecoration(labelText: "Last name", border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: countryCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Country",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: TextField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Phone",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: igCtrl,
                            decoration: const InputDecoration(labelText: "Instagram", border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dctx) => AlertDialog(
                                        title: const Text("Confirm edit"),
                                        content: const Text("Save changes to this client?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text("No")),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff721c80)),
                                            onPressed: () => Navigator.pop(dctx, true),
                                            child: const Text("Yes", style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (ok != true) return;
                                    await saveEdits();

                                    if (!ctx.mounted) return;
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text("Client updated")),
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("Edit / Save"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dctx) => AlertDialog(
                                        title: const Text("Delete client?"),
                                        content: const Text("This will delete the client document. Continue?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text("No")),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(dctx, true),
                                            child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok != true) return;

                                    await deleteClient();
                                    if (!ctx.mounted) return;

                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text("Client deleted")),
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text("Delete"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CTA to booking
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff721c80),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          // Cambia tab a Booking y le pasa intención
                          context.read<AdminNavProvider>().goToBookingWithClient(clientId);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.edit_calendar_outlined, color: Colors.white),
                        label: const Text(
                          "Create appointment for this client",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    nameCtrl.dispose();
    fnCtrl.dispose();
    lnCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    igCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final nav = context.watch<AdminNavProvider>();

    // auto-open si viene desde HomeAdmin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final openId = nav.openClientId;
      if (openId != null) {
        _openClientBottomSheet(context, openId);
        context.read<AdminNavProvider>().clearOpenClient();
      }
    });

    final stream = FirebaseFirestore.instance
        .collection('clients')
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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
                    const Text(
                      "Clients",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.95),
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Search by tokens (name/phone/instagram)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
                  final q = _searchCtrl.text.trim().toLowerCase();

                  final filtered = q.isEmpty
                      ? docs
                      : docs.where((d) {
                          final data = d.data();
                          final search = (data['search'] as List<dynamic>?)
                                  ?.map((e) => e.toString().toLowerCase())
                                  .toList() ??
                              [];
                          return search.any((t) => t.contains(q));
                        }).toList();

                  if (filtered.isEmpty) {
                    return Text(s.noMatches, style: TextStyle(color: Colors.grey[700]));
                  }

                  return Column(
                    children: filtered.map((d) {
                      return _clientCard(
                        context: context,
                        clientId: d.id,
                        data: d.data(),
                        onOpen: () => _openClientBottomSheet(context, d.id),
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
