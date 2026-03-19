// lib/screens/clients/client_profile_screen.dart
//
// Fixes v3:
//  1. Switch/botón verde: switch izquierda, botón verde derecha.
//     Botón verde SOLO visible si _looking==true.
//     No se puede crear request si switch off.
//  2. Availability pill en BookingRequestCard muestra la fecha real
//     (igual que en home) cargando appointmentsDocs via StreamBuilder.
//  3. Stats: sin container, pills directamente sobre el gradiente,
//     "Last appointment" arriba, 4 pills en una sola línea responsive (FittedBox).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/repositories/booking_request_repo.dart';
import 'package:salon_app/services/availability_service.dart';
import 'package:salon_app/utils/app_time_picker.dart';
import 'package:salon_app/utils/booking_request_utils.dart';
import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/utils/time_of_day_utils.dart';
import 'package:salon_app/widgets/async_optimistic_switch.dart';
import 'package:salon_app/widgets/booking_request_card.dart';
import 'package:salon_app/widgets/booking_request_create_form.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key, required this.clientId});
  final String clientId;

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen>
    with SingleTickerProviderStateMixin {
  static const Color kPurple = Color(0xff721c80);
  static const Color kGreen  = Color(0xff2e7d32);

  late final TabController _tabController;
  late final BookingRequestRepo _brRepo;
  final _avSvc = AvailabilityService();

  Map<String, dynamic> _clientData = {};
  bool _loading = true;
  bool _looking = false;

  final _fnCtrl      = TextEditingController();
  final _lnCtrl      = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _igCtrl      = TextEditingController();

  String? _brWorkerId;
  String? _brServiceId;
  Map<String, dynamic>? _brServiceData;
  int _brDurationMin = 30;
  final List<String>           _brDayKeys = [];
  final List<Map<String, int>> _brRanges  = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _brRepo = BookingRequestRepo(FirebaseFirestore.instance);
    _loadClient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fnCtrl.dispose(); _lnCtrl.dispose(); _countryCtrl.dispose();
    _phoneCtrl.dispose(); _igCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _loadClient() async {
    final snap = await FirebaseFirestore.instance
        .collection('clients').doc(widget.clientId).get();
    _clientData = snap.data() ?? {};
    _fnCtrl.text      = (_clientData['firstName'] ?? '').toString();
    _lnCtrl.text      = (_clientData['lastName']  ?? '').toString();
    _countryCtrl.text = (_clientData['country']   ?? '').toString();
    _phoneCtrl.text   = (_clientData['phone']     ?? '').toString();
    _igCtrl.text      = (_clientData['instagram'] ?? '').toString();
    _looking = _clientData['bookingRequestActive'] == true;
    if (mounted) setState(() => _loading = false);
  }

  String _fullName() {
    final v = '${(_clientData['firstName'] ?? '').toString().trim()} '
              '${(_clientData['lastName']  ?? '').toString().trim()}'.trim();
    return v.isEmpty ? S.of(context).clientFallback : v;
  }

  String _contactLine() {
    final c = _num('country'); final p = _num('phone');
    final ig = (_clientData['instagram'] ?? '').toString().trim();
    final parts = <String>[];
    if (c > 0 && p > 0) parts.add('+$c $p');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  int _num(String k) {
    final v = _clientData[k];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  Map<String, dynamic> get _stats =>
      (_clientData['stats'] as Map?)?.cast<String, dynamic>() ?? {};

  // ── Streams ───────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> _upcomingStream() =>
      FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .where('status', isEqualTo: 'scheduled')
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('appointmentDate')
          .limit(50)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _pastStream() =>
      FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .where('appointmentDate', isLessThan: Timestamp.now())
          .orderBy('appointmentDate', descending: true)
          .limit(100)
          .snapshots();

  // ── Range helpers ─────────────────────────────────────────────────────────

  bool _rangesFitDuration(List<Map<String, int>> ranges, int dur) {
    if (ranges.isEmpty) return true;
    for (final r in ranges) {
      if ((r['endMin'] ?? 0) - (r['startMin'] ?? 0) < dur) return false;
    }
    return true;
  }

  Future<void> _addBrDay() async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: today, lastDate: DateTime(now.year + 2), initialDate: today,
    );
    if (picked == null) return;
    final key = BookingRequestUtils.yyyymmdd(picked);
    setState(() {
      if (!_brDayKeys.contains(key)) _brDayKeys.add(key);
      _brDayKeys.sort();
    });
  }

  Future<void> _addBrRange() async {
    final start = await AppTimePicker.pick5m(
        context: context, initial: const TimeOfDay(hour: 9, minute: 0));
    if (start == null) return;
    final fs = TimeOfDayUtils.clamp(start,
        minMinutes: AvailabilityService.bizStartMin, maxMinutes: AvailabilityService.bizEndMax - 15);
    final end = await AppTimePicker.pick5m(
        context: context,
        initial: TimeOfDayUtils.fromMinutes(
            TimeOfDayUtils.toMinutes(fs) + 15));
    if (end == null) return;
    var fe = TimeOfDayUtils.clamp(end,
        minMinutes: AvailabilityService.bizStartMin + 15, maxMinutes: AvailabilityService.bizEndMax);
    if (TimeOfDayUtils.isBefore(fe, fs)) fe = fs;
    setState(() => _brRanges.add(BookingRequestUtils.range(fs, fe)));
  }

  // ── Booking request actions ───────────────────────────────────────────────────

  Future<void> _confirmAndDisableLooking() async {
    final s = S.of(context);
    final docs = await _brRepo.getActiveRequestsForClient(widget.clientId);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.disableBookingRequests),
        content: Text(docs.isEmpty
            ? s.disableBookingConfirmNone
            : s.disableBookingConfirmMany(docs.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (docs.isNotEmpty) await _brRepo.deleteAllActiveForClient(widget.clientId);
    await FirebaseFirestore.instance.collection('clients')
        .doc(widget.clientId).set({
      'bookingRequestActive': false,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _looking = false);
  }

  Future<void> _createRequest() async {
    final s = S.of(context);
    if (_brServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.selectProcedureFirst)));
      return;
    }
    _brServiceData ??= (await FirebaseFirestore.instance
        .collection('services').doc(_brServiceId!).get()).data();
    final svc     = _brServiceData ?? {};
    final nameKey = (svc['name'] ?? '').toString();
    final label   = nameKey.isNotEmpty ? nameKey : _brServiceId!;
    final dur     = svc['durationMin'] is num
        ? (svc['durationMin'] as num).toInt() : 30;

    await _brRepo.upsertRequest(
      workerId: _brWorkerId,
      clientId: widget.clientId,
      serviceId: _brServiceId!,
      serviceNameKey: nameKey,
      serviceNameLabel: label,
      durationMin: dur,
      exactSlots: const [],
      preferredDays: List.from(_brDayKeys),
      preferredTimeRanges: List.from(_brRanges),
    );
    await FirebaseFirestore.instance.collection('clients')
        .doc(widget.clientId).set({
      'bookingRequestActive': true,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {
      _looking = true;
      _brDayKeys.clear(); _brRanges.clear();
      _brWorkerId = null; _brServiceId = null;
      _brServiceData = null; _brDurationMin = 30;
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.bookingRequestCreated)));
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────────

  Future<void> _openEditSheet() async {
    final s = S.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + inset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.editClient,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 14),
                TextField(controller: _fnCtrl,
                    decoration: InputDecoration(labelText: s.firstNameLabel,
                        border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _lnCtrl,
                    decoration: InputDecoration(labelText: s.lastNameLabel,
                        border: const OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(flex: 2, child: TextField(
                      controller: _countryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.countryCode,
                          border: const OutlineInputBorder()))),
                  const SizedBox(width: 10),
                  Expanded(flex: 4, child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: s.phoneLabel,
                          border: const OutlineInputBorder()))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: _igCtrl,
                    decoration: InputDecoration(labelText: s.instagram,
                        border: const OutlineInputBorder())),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('clients').doc(widget.clientId).set({
                        'firstName': _fnCtrl.text.trim(),
                        'lastName':  _lnCtrl.text.trim(),
                        'country':   int.tryParse(_countryCtrl.text.trim()) ?? 0,
                        'phone':     int.tryParse(_phoneCtrl.text.trim()) ?? 0,
                        'instagram': _igCtrl.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.clientUpdated)));
                      await _loadClient();
                    },
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: Text(s.saveClient,
                      style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBookingRequestSheet() async {
    // FIX 1: No se puede abrir si el switch no está activo
    if (!_looking) return;

    setState(() {
      _brDayKeys.clear(); _brRanges.clear();
      _brWorkerId = null; _brServiceId = null;
      _brServiceData = null; _brDurationMin = 30;
    });

    final s = S.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + inset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.newBookingRequest,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 14),
                  BookingRequestCreateForm(
                    selectedWorkerId: _brWorkerId,
                    onWorkerChanged: (v) => setLocal(() => _brWorkerId = v),
                    selectedServiceId: _brServiceId,
                    onServiceChanged: (sid) async {
                      if (sid == null || sid.isEmpty) {
                        setLocal(() {
                          _brServiceId = null; _brServiceData = null;
                          _brDurationMin = 30;
                        });
                        return;
                      }
                      final doc = await FirebaseFirestore.instance
                          .collection('services').doc(sid).get();
                      final data = doc.data() ?? {};
                      final dur = data['durationMin'] is num
                          ? (data['durationMin'] as num).toInt() : 30;
                      setLocal(() {
                        _brServiceId   = sid;
                        _brServiceData = data;
                        _brDurationMin = dur;
                      });
                    },
                    selectedDays: _brDayKeys,
                    selectedRanges: _brRanges,
                    onAddDay: () async { await _addBrDay(); setLocal(() {}); },
                    onRemoveDayKey: (k) => setLocal(() => _brDayKeys.remove(k)),
                    onAddRange: () async { await _addBrRange(); setLocal(() {}); },
                    onRemoveRangeAt: (i) {
                      if (i < 0 || i >= _brRanges.length) return;
                      setLocal(() => _brRanges.removeAt(i));
                    },
                    onCreate: _createRequest,
                    purple: kPurple,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editRequestSheet({
    required String requestId,
    required Map<String, dynamic> br,
  }) async {
    String? workerId = (br['workerId'] as String?)?.trim();
    if (workerId != null && workerId.isEmpty) workerId = null;
    String? serviceId = (br['serviceId'] as String?)?.trim();
    if (serviceId != null && serviceId.isEmpty) serviceId = null;

    final dayKeys = (br['preferredDays'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ?? <String>[];

    final rangeList = <Map<String, int>>[];
    for (final rr in (br['preferredTimeRanges'] as List?) ?? const []) {
      if (rr is! Map) continue;
      final m  = Map<String, dynamic>.from(rr);
      final s  = (m['startMin'] ?? m['start']);
      final e  = (m['endMin']   ?? m['end']);
      final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? -1;
      final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? -1;
      if (sm >= 0 && em > sm) rangeList.add({'startMin': sm, 'endMin': em});
    }

    bool saving = false;

    final s = S.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> save() async {
              if (saving) return;
              if (serviceId == null || serviceId!.isEmpty) {
                final s = S.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.selectProcedureFirst)));
                return;
              }
              setLocal(() => saving = true);
              try {
                final svcDoc = await FirebaseFirestore.instance
                    .collection('services').doc(serviceId!).get();
                final svc     = svcDoc.data() ?? {};
                final nameKey = (svc['name'] ?? '').toString();
                final label   = nameKey.isNotEmpty ? nameKey : serviceId!;
                final dur     = svc['durationMin'] is num
                    ? (svc['durationMin'] as num).toInt() : 30;
                if (!_rangesFitDuration(List<Map<String, int>>.from(rangeList), dur)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Range must be at least $dur min')));
                  return;
                }
                await _brRepo.updateRequest(
                  requestId: requestId,
                  workerId: workerId,
                  serviceId: serviceId!,
                  serviceNameKey: nameKey,
                  serviceNameLabel: label,
                  durationMin: dur,
                  preferredDays: List<String>.from(dayKeys),
                  preferredTimeRanges: List<Map<String, int>>.from(rangeList),
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.requestUpdated)));
              } finally {
                if (ctx.mounted) setLocal(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + inset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(child: Text(s.editRequest,
                          style: const TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 16))),
                      IconButton(
                          onPressed: saving ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close)),
                    ]),
                    const SizedBox(height: 10),
                    BookingRequestCreateForm(
                      selectedWorkerId: workerId,
                      onWorkerChanged: (v) => setLocal(() => workerId = v),
                      selectedServiceId: serviceId,
                      onServiceChanged: (newSid) async {
                        if (newSid == null || newSid.isEmpty) {
                          setLocal(() => serviceId = null); return;
                        }
                        setLocal(() => serviceId = newSid);
                      },
                      selectedDays: dayKeys,
                      selectedRanges: rangeList,
                      onAddDay: () async {
                        final now   = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final p = await showDatePicker(
                          context: ctx,
                          firstDate: today,
                          lastDate: DateTime(now.year + 2),
                          initialDate: today,
                        );
                        if (p == null) return;
                        final key = BookingRequestUtils.yyyymmdd(p);
                        setLocal(() {
                          if (!dayKeys.contains(key)) dayKeys.add(key);
                          dayKeys.sort();
                        });
                      },
                      onRemoveDayKey: (k) => setLocal(() => dayKeys.remove(k)),
                      onAddRange: () async {
                        final s = await AppTimePicker.pick5m(
                            context: ctx,
                            initial: const TimeOfDay(hour: 9, minute: 0));
                        if (s == null) return;
                        final sMin = s.hour * 60 + s.minute;
                        final e = await AppTimePicker.pick5m(
                            context: ctx,
                            initial: TimeOfDay(
                                hour: (sMin ~/ 60).clamp(0, 23),
                                minute: sMin % 60));
                        if (e == null) return;
                        final eMin = e.hour * 60 + e.minute;
                        if (eMin <= sMin) return;
                        setLocal(() =>
                            rangeList.add({'startMin': sMin, 'endMin': eMin}));
                      },
                      onRemoveRangeAt: (i) {
                        if (i < 0 || i >= rangeList.length) return;
                        setLocal(() => rangeList.removeAt(i));
                      },
                      onCreate: save,
                      purple: kPurple,
                    ),
                    if (saving)
                      const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: CircularProgressIndicator()),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Appointment card ──────────────────────────────────────────────────────────

  Widget _apptCard(Map<String, dynamic> d, {bool isPast = false}) {
    final ts         = d['appointmentDate'];
    final date       = ts is Timestamp ? ts.toDate() : null;
    final dateStr    = date != null
        ? DateTimeUtils.formatYyyyMmDdToDdMmYyyy(DateTimeUtils.yyyymmdd(date))
        : (d['date'] ?? '').toString();
    final timeStr    = date != null
        ? DateTimeUtils.hhmmFromMinutes(date.hour * 60 + date.minute) : '';
    final service    = (d['serviceName'] ?? d['service'] ?? '').toString();
    final rawStatus  = (d['status'] ?? '').toString();
    final workerName = (d['workerName'] ?? d['workerId'] ?? '').toString();

    final displayStatus = (isPast && rawStatus == 'scheduled')
        ? 'attended'
        : rawStatus;

    final statusColor = {
      'scheduled':      kPurple,
      'done':           Colors.green,
      'attended':       Colors.green,
      'cancelled':      Colors.orange,
      'noShow':         Colors.red,
    }[displayStatus] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.isNotEmpty ? service : '—',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('$dateStr${timeStr.isNotEmpty ? "  ·  $timeStr" : ""}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                if (workerName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(workerName,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(displayStatus,
                style: TextStyle(color: statusColor,
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── FIX 3: Stats directamente sobre el gradiente ──────────────────────────────
  // Sin container propio, pills sobre el morado, last visit arriba,
  // 4 stats en una línea con FittedBox para ser responsive.

  // ── Stats calculadas en tiempo real desde appointments ───────────────────────
  //
  // No usamos stats.totalScheduled/totalDone del doc de cliente porque:
  //   - scheduled pasado = attended (ya ocurrió aunque no se marcó como done)
  //   - La fuente de verdad es la colección appointments, no los contadores
  //
  // Lógica:
  //   attended  = done  +  scheduled con fecha pasada
  //   cancelled = cancelled
  //   noShow    = noShow
  //   requested = total docs (todos los estados)

  Widget _statsOverlay() {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .snapshots(),
      builder: (_, snap) {
        // Mientras carga, usamos los contadores del doc del cliente como fallback
        if (!snap.hasData) {
          final s         = _stats;
          final requested = (s['totalAppointments'] as num?)?.toInt() ?? 0;
          final attended  = ((s['totalDone']       as num?)?.toInt() ?? 0) +
                            ((s['totalScheduled']  as num?)?.toInt() ?? 0);
          final cancelled = (s['totalCancelled']   as num?)?.toInt() ?? 0;
          final noShow    = (s['totalNoShow']       as num?)?.toInt() ?? 0;
          final lastTs    = s['lastAppointmentAt']  as Timestamp?;
          final lastSum   = (s['lastAppointmentSummary'] ?? '').toString();
          return _statsContent(
            requested: requested,
            attended: attended,
            cancelled: cancelled,
            noShow: noShow,
            lastTs: lastTs,
            lastSummary: lastSum,
          );
        }

        final docs = snap.data!.docs;

        int requested = docs.length;
        int attended  = 0;
        int cancelled = 0;
        int noShow    = 0;

        Timestamp? lastAttendedTs;
        String lastAttendedSummary = '';

        for (final d in docs) {
          final data   = d.data();
          final status = (data['status'] ?? '').toString();
          final ts     = data['appointmentDate'];
          final isPast = ts is Timestamp && ts.toDate().isBefore(now);

          // attended = done  OR  scheduled ya pasado (ocurrió aunque no marcado)
          if (status == 'done' || (status == 'scheduled' && isPast)) {
            attended++;
            // El más reciente de los attended → last attended appointment
            if (ts is Timestamp) {
              if (lastAttendedTs == null ||
                  ts.toDate().isAfter(lastAttendedTs.toDate())) {
                lastAttendedTs = ts;
                lastAttendedSummary =
                    (data['serviceName'] ?? data['serviceNameLabel'] ?? '')
                        .toString();
              }
            }
          } else if (status == 'cancelled') {
            cancelled++;
          } else if (status == 'noShow') {
            noShow++;
          }
        }

        // Si no hay attended calculados, fallback al lastAppointmentAt del doc
        final s = _stats;
        final fallbackTs  = lastAttendedTs ?? (s['lastAppointmentAt'] as Timestamp?);
        final fallbackSum = lastAttendedSummary.isNotEmpty
            ? lastAttendedSummary
            : (s['lastAppointmentSummary'] ?? '').toString();

        return _statsContent(
          requested: requested,
          attended: attended,
          cancelled: cancelled,
          noShow: noShow,
          lastTs: fallbackTs,
          lastSummary: fallbackSum,
        );
      },
    );
  }

  Widget _statsContent({
    required int requested,
    required int attended,
    required int cancelled,
    required int noShow,
    required Timestamp? lastTs,
    required String lastSummary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Last appointment — ARRIBA
        if (lastTs != null) ...[
          () {
            final d    = lastTs.toDate();
            final date = DateTimeUtils.formatYyyyMmDdToDdMmYyyy(
                DateTimeUtils.yyyymmdd(d));
            final time = DateTimeUtils.hhmmFromMinutes(d.hour * 60 + d.minute);
            return Text(
              'Last attended appointment  ·  $date  ·  $time'
              '${lastSummary.isNotEmpty ? "  ·  $lastSummary" : ""}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }(),
          const SizedBox(height: 6),
        ],

        // 4 pills en una línea — FittedBox responsive
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sPill('Requested: $requested'),
              const SizedBox(width: 6),
              _sPill('Attended: $attended',
                  bg: Colors.green.withOpacity(0.45)),
              const SizedBox(width: 6),
              _sPill('Cancelled: $cancelled',
                  bg: Colors.orange.withOpacity(0.45)),
              const SizedBox(width: 6),
              _sPill('No-show: $noShow',
                  bg: Colors.red.withOpacity(0.45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sPill(String label, {Color bg = const Color(0x33FFFFFF)}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w800)),
      );

  // ── Upcoming tab ──────────────────────────────────────────────────────────────

  Widget _buildUpcomingTab() {
    final s = S.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FIX 1: Switch izquierda, botón verde derecha (solo si _looking) ──
          AppSectionCard(
            title: s.bookingRequest,
            child: Row(
              children: [
                // Switch
                AsyncOptimisticSwitch(
                  value: _looking,
                  switchActiveColor: kPurple,
                  onSave: (v) async {
                    if (!v) { await _confirmAndDisableLooking(); return; }
                    setState(() => _looking = true);
                    await FirebaseFirestore.instance
                        .collection('clients').doc(widget.clientId).set({
                      'bookingRequestActive': true,
                      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _looking ? s.lookingForAppointment : s.notLooking,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                // Botón + verde — SOLO si looking==true
                if (_looking)
                  AppIconPillButton(
                    icon: Icons.add,
                    color: kGreen,
                    size: 32,
                    iconSize: 16,
                    tooltip: s.newBookingRequest,
                    onTap: _openBookingRequestSheet,
                  ),
              ],
            ),
          ),

          // ── Active booking requests (con availability real) ───────────────
          const SizedBox(height: 12),
          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _brRepo.streamActiveRequestsForClient(widget.clientId),
            builder: (_, brSnap) {
              final brDocs = brSnap.data ?? [];
              if (brDocs.isEmpty) return const SizedBox.shrink();

              final brDataList = brDocs
                  .map((d) => d.data())
                  .toList();

              // Stream de appointments en el rango de fechas de los requests
              final apptStream = _avSvc.apptStreamForRequests(brDataList);

              Widget buildCards(
                List<QueryDocumentSnapshot<Map<String, dynamic>>> apptDocs,
              ) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.activeBookingRequests,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...brDocs.map((d) {
                      final br   = d.data();
                      final info = _avSvc.availabilityFor(br: br, appts: apptDocs);
                      final lbl  = _avSvc.pillLabel(info.status, info.nextStart);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BookingRequestCard(
                          requestId: d.id,
                          br: br,
                          purple: kPurple,
                          availability: info.status,
                          availabilityLabel: lbl,
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                title: Text(s.deleteRequestTitle),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dctx, false),
                                      child: Text(s.no)),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(dctx, true),
                                    child: Text(S.of(context).delete,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            await _brRepo.deleteRequest(d.id);
                          },
                          onEditRequest: () =>
                              _editRequestSheet(requestId: d.id, br: br),
                        ),
                      );
                    }),
                  ],
                );
              }

              if (apptStream == null) {
                return buildCards(const []);
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: apptStream,
                builder: (_, apptSnap) {
                  final apptDocs = apptSnap.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  return buildCards(apptDocs);
                },
              );
            },
          ),

          // ── Upcoming appointments ─────────────────────────────────────────
          const SizedBox(height: 16),
          Text(s.upcomingAppointments,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _upcomingStream(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: kPurple));
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text(s.noUpcomingAppointments,
                    style: TextStyle(color: Colors.grey[700]));
              }
              return Column(
                  children: docs.map((d) => _apptCard(d.data())).toList());
            },
          ),
        ],
      ),
    );
  }

  // ── Past tab ──────────────────────────────────────────────────────────────────

  Widget _buildPastTab() {
    final s = S.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pastStream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPurple));
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}',
              style: const TextStyle(color: Colors.red)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text(s.noPastAppointments,
              style: TextStyle(color: Colors.grey[700])));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) => _apptCard(docs[i].data(), isPast: true),
        );
      },
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────

  Widget _bottomBar() {
    final s = S.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            AppIconPillButton(
              icon: Icons.edit_outlined,
              color: Colors.grey[700]!,
              size: 44,
              tooltip: s.editClient,
              onTap: _openEditSheet,
            ),
            const Spacer(),
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  context.read<AdminNavProvider>()
                      .goToBookingWithClient(widget.clientId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.edit_calendar_outlined,
                    color: Colors.white, size: 18),
                label: Text(s.newAppointment,
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const Spacer(),
            AppIconPillButton(
              icon: Icons.delete_outline,
              color: Colors.red,
              size: 44,
              tooltip: s.deleteClient,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: Text(s.deleteClientTitle),
                    content: Text(s.deleteClientConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx, false),
                          child: Text(s.no)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(dctx, true),
                        child: Text(s.delete,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await FirebaseFirestore.instance
                    .collection('clients').doc(widget.clientId).delete();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.clientDeleted)));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: kPurple)));
    }

    return Scaffold(
      body: Column(
        children: [
          AppGradientHeader(
            title: _fullName(),
            subtitle: _contactLine().isNotEmpty ? _contactLine() : null,
            height: 185,
            // FIX 3: stats directamente como child del header (sobre el gradiente)
            child: _statsOverlay(),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: kPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPurple,
              tabs: [Tab(text: S.of(context).upcoming), Tab(text: S.of(context).past)],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUpcomingTab(), _buildPastTab()],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }
}
