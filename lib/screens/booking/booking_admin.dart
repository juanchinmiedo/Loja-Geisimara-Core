import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:salon_app/components/date_piceker.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/services/client_service.dart';
import 'package:salon_app/services/conflict_service.dart';
import 'package:salon_app/screens/booking/create_appointment_dialog.dart';
import 'package:salon_app/screens/booking/edit_appointment_dialog.dart';

class BookingAdminScreen extends StatefulWidget {
  const BookingAdminScreen({super.key, this.preselectedClientId});

  final String? preselectedClientId;

  @override
  State<BookingAdminScreen> createState() => _BookingAdminScreenState();
}

class _BookingAdminScreenState extends State<BookingAdminScreen> {
  DateTime _selectedDay =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  late final ClientService _clientService;
  late final ConflictService _conflictService;

  StreamSubscription? _clientsSub;
  StreamSubscription? _servicesSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _clients = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _services = [];

  bool _autoCreateOpened = false; // ✅ evita abrir 2 veces

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _clientService = ClientService(db);
    _conflictService = ConflictService(db);

    // ✅ cache clients
    _clientsSub = db
        .collection('clients')
        .orderBy('updatedAt', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() => _clients = snap.docs);
      _tryAutoOpenCreateIfNeeded();
    });

    // ✅ cache services
    _servicesSub = db.collection('services').snapshots().listen((snap) {
      if (!mounted) return;
      setState(() => _services = snap.docs);
      _tryAutoOpenCreateIfNeeded();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoOpenCreateIfNeeded();
    });
  }

  void _tryAutoOpenCreateIfNeeded() {
    if (!mounted) return;

    final pid = widget.preselectedClientId;
    if (pid == null || pid.isEmpty) return;

    if (_services.isEmpty) return;
    if (_autoCreateOpened) return;

    _autoCreateOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openCreateAppointmentDialog(preselectedClientId: pid);
    });
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _servicesSub?.cancel();
    super.dispose();
  }

  int _minutesOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Color _conflictColorFromMaxOverlap(int maxOverlapMin) {
    if (maxOverlapMin <= 0) return Colors.green;
    if (maxOverlapMin < 30) return Colors.amber;
    return Colors.red;
  }

  Future<void> _openCreateAppointmentDialog({String? preselectedClientId}) async {
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Services are still loading...")),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateAppointmentDialog(
        selectedDay: _selectedDay,
        clients: _clients,
        services: _services,
        clientService: _clientService,
        conflictService: _conflictService,
        preselectedClientId: preselectedClientId,
      ),
    );
  }

  Future<void> _openEditAppointmentDialog({
    required String appointmentId,
    required Map<String, dynamic> data,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditAppointmentDialog(
        appointmentId: appointmentId,
        data: data,
        selectedDay: _selectedDay,
        services: _services,
        conflictService: _conflictService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayStart = Timestamp.fromDate(_startOfDay(_selectedDay));
    final dayEnd = Timestamp.fromDate(_endOfDay(_selectedDay));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppGradientHeader(
              title: "Admin Schedule",
              height: 240,
              padding: const EdgeInsets.only(top: 38, left: 18, right: 18),
              centerTitle: true,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w500,
              ),
              child: CustomDatePicker(
                initialDate: _selectedDay,
                onDateChange: (d) => setState(() => _selectedDay = d),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    "Appointments",
                    style: TextStyle(
                      color: Color.fromARGB(255, 45, 42, 42),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _openCreateAppointmentDialog(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff721c80),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Add",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('status', isEqualTo: 'scheduled')
                    .where('appointmentDate', isGreaterThanOrEqualTo: dayStart)
                    .where('appointmentDate', isLessThanOrEqualTo: dayEnd)
                    .orderBy('appointmentDate')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator(color: Colors.purple)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Error appointments: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      child: Text(
                        "No appointments for this day",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  final items = docs.map((d) {
                    final data = d.data() as Map<String, dynamic>? ?? {};
                    final ts = data['appointmentDate'];
                    final start = ts is Timestamp ? ts.toDate() : DateTime.now();

                    final dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 0;
                    final safeDur = dur <= 0 ? 0 : dur;
                    final end = start.add(Duration(minutes: safeDur));

                    return _ApptVM(
                      id: d.id,
                      doc: d as QueryDocumentSnapshot,
                      data: data,
                      start: start,
                      end: end,
                      durationMin: safeDur,
                    );
                  }).toList();

                  for (final a in items) {
                    int maxOverlap = 0;
                    for (final b in items) {
                      if (a.id == b.id) continue;
                      final overlap = _minutesOverlap(a.start, a.end, b.start, b.end);
                      if (overlap > maxOverlap) maxOverlap = overlap;
                    }
                    a.maxOverlapMin = maxOverlap;
                    a.dotColor = _conflictColorFromMaxOverlap(maxOverlap);
                  }

                  return Column(
                    children: items.map((vm) {
                      return _AdminAppointmentTile(
                        doc: vm.doc,
                        dotColor: vm.dotColor ?? Colors.green,
                        onTap: () => _openEditAppointmentDialog(
                          appointmentId: vm.id,
                          data: vm.data,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ApptVM {
  final String id;
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final DateTime start;
  final DateTime end;
  final int durationMin;

  int maxOverlapMin = 0;
  Color? dotColor;

  _ApptVM({
    required this.id,
    required this.doc,
    required this.data,
    required this.start,
    required this.end,
    required this.durationMin,
  });
}

class _AdminAppointmentTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Color dotColor;
  final VoidCallback onTap;

  const _AdminAppointmentTile({
    required this.doc,
    required this.dotColor,
    required this.onTap,
  });

  String _s(Map<String, dynamic> data, String k, String fb) {
    final v = data[k];
    return v is String && v.isNotEmpty ? v : fb;
  }

  double _n(Map<String, dynamic> data, String k) {
    final v = data[k];
    if (v is num) return v.toDouble();
    return 0;
  }

  int _i(Map<String, dynamic> data, String k) {
    final v = data[k];
    if (v is num) return v.toInt();
    return 0;
  }

  DateTime? _ts(Map<String, dynamic> data, String k) {
    final v = data[k];
    if (v is Timestamp) return v.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    final dt = _ts(data, 'appointmentDate');

    final durationMin = _i(data, 'durationMin');
    final safeDur = durationMin <= 0 ? 0 : durationMin;

    String fmt(DateTime d) => "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

    final startText = (dt == null) ? "--:--" : fmt(dt);
    final endText = (dt == null) ? "--:--" : fmt(dt.add(Duration(minutes: safeDur)));

    final key = _s(data, 'serviceNameKey', '');
    final serviceName = key.isNotEmpty ? trServiceOrAddon(context, key) : _s(data, 'serviceName', 'Service');

    final clientName = _s(data, 'clientName', 'Client');

    final ctry = data['clientCountry'];
    final ph = data['clientPhone'];

    final phoneText = (ctry is num && ph is num && ctry > 0 && ph > 0)
        ? "+${ctry.toInt()} ${ph.toInt()}"
        : "";

    final ig = _s(data, 'clientInstagram', '');
    final total = _n(data, 'total');

    final contact = [
      phoneText.isNotEmpty ? phoneText : null,
      ig.isNotEmpty ? '@$ig' : null,
    ].whereType<String>().join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xff721c80).withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      startText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xff721c80),
                        fontSize: 13,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      endText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xff721c80),
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.isEmpty ? clientName : "$clientName • $contact",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (durationMin > 0) ...[
                    const SizedBox(height: 2),
                    Text("${durationMin}m", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total > 0 ? "€${total.toStringAsFixed(0)}" : "",
              style: const TextStyle(color: Color(0xff721c80), fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
