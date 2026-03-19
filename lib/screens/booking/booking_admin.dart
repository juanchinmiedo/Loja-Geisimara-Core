// lib/screens/booking/booking_admin.dart
//
// CAMBIOS vs versión anterior (commit 3):
//  • _buildWeekView() pasa blockedSlotRepo y workerId a WeekCalendarView
//  • _buildDayView() muestra franjas bloqueadas como banners negros
//    en la lista, entre los appointments existentes
//  • Todo lo demás (dialogs, lifecycle, day tile) idéntico

import 'dart:async';
import 'package:salon_app/generated/l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/provider/booking_view_provider.dart';

import 'package:salon_app/components/pretty_date_strip.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';

import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/utils/localization_helper.dart';
import 'package:salon_app/utils/pending_confirmation_utils.dart';

import 'package:salon_app/widgets/worker_selector_pills.dart';
import 'package:salon_app/widgets/booking_view_toggle.dart';

import 'package:salon_app/services/client_service.dart';
import 'package:salon_app/services/conflict_service.dart';

import 'package:salon_app/repositories/blocked_slot_repo.dart';

import 'package:salon_app/screens/booking/past_appointment_dialog.dart';
import 'package:salon_app/screens/booking/create_appointment_dialog.dart';
import 'package:salon_app/screens/booking/edit_appointment_dialog.dart';
import 'package:salon_app/screens/booking/week_calendar_view.dart';
import 'package:salon_app/screens/booking/block_slot_dialog.dart';

class BookingAdminScreen extends StatefulWidget {
  const BookingAdminScreen({super.key, this.preselectedClientId});
  final String? preselectedClientId;

  @override
  State<BookingAdminScreen> createState() => _BookingAdminScreenState();
}

class _BookingAdminScreenState extends State<BookingAdminScreen> {
  DateTime _selectedDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  late final ClientService _clientService;
  late final ConflictService _conflictService;
  late final BlockedSlotRepo _blockedSlotRepo;

  StreamSubscription? _clientsSub;
  StreamSubscription? _servicesSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _clients  = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _services = [];

  bool _autoCreateOpened = false;

  // ── Color helpers ────────────────────────────────────────────────────────────

  Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return const Color(0xff721c80);
    return Color(int.parse('FF$clean', radix: 16));
  }

  Map<String, Color> _serviceColorsById() {
    final out = <String, Color>{};
    for (final s in _services) {
      final hex = (s.data()['colorHex'] ?? '').toString();
      if (hex.isNotEmpty) out[s.id] = _colorFromHex(hex);
    }
    return out;
  }

  // ── Week helpers ─────────────────────────────────────────────────────────────

  DateTime _startOfWeekMonday(DateTime d) {
    final x    = DateTime(d.year, d.month, d.day);
    final diff = x.weekday - DateTime.monday;
    return x.subtract(Duration(days: diff));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentWeek(DateTime weekStart) {
    final now   = DateTime.now();
    final wsNow = _startOfWeekMonday(now);
    return _isSameDay(wsNow, weekStart);
  }

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final db          = FirebaseFirestore.instance;
    _clientService    = ClientService(db);
    _conflictService  = ConflictService(db);
    _blockedSlotRepo  = BlockedSlotRepo(db);

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

    _servicesSub = db.collection('services').limit(100).snapshots().listen((snap) {
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

  // ── Conflict helpers ─────────────────────────────────────────────────────────

  int _minutesOverlap(
      DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end   = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    final diff  = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Color _conflictColorFromMaxOverlap(int maxOverlapMin) {
    if (maxOverlapMin <= 0) return Colors.green;
    if (maxOverlapMin < 30) return Colors.amber;
    return Colors.red;
  }

  // ── Dialog openers ───────────────────────────────────────────────────────────

  Future<void> _openCreateAppointmentDialog({
    String? preselectedClientId,
    TimeOfDay? initialStartTime,
    DateTime? selectedDayOverride,
  }) async {
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Services are still loading...')));
      return;
    }
    final day = selectedDayOverride ?? _selectedDay;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateAppointmentDialog(
        selectedDay: day,
        clients: _clients,
        services: _services,
        clientService: _clientService,
        conflictService: _conflictService,
        preselectedClientId: preselectedClientId,
        initialStartTime: initialStartTime,
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

  Future<void> _openPastAppointmentDialog({
    required String appointmentId,
    required Map<String, dynamic> data,
    required DateTime selectedDayOverride,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PastAppointmentDialog(
        appointmentId: appointmentId,
        data: data,
        selectedDay: selectedDayOverride,
        services: _services,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

@override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dayStart  = Timestamp.fromDate(_startOfDay(_selectedDay));
    final dayEnd    = Timestamp.fromDate(_endOfDay(_selectedDay));
    final userProv  = context.watch<UserProvider>();
    final workerFilter = userProv.workerIdForQueries();
    final canCreate = !(userProv.isAdmin &&
        (userProv.selectedWorkerId == null ||
            userProv.selectedWorkerId!.isEmpty));
    final view      = context.watch<BookingViewProvider>();

    Widget headerAndControls() {
      return Column(
        children: [
          AppGradientHeader(
            title: s.adminSchedule,
            height: 240,
            padding: const EdgeInsets.only(top: 46, left: 18, right: 18),
            child: PrettyDateStrip(
              selectedDate: _selectedDay,
              onChange: (d) => setState(() => _selectedDay = d),
            ),
          ),
          const SizedBox(height: 10),
          const WorkerSelectorPills(),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Text(
                  s.appointments,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 45, 42, 42),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const BookingViewToggle(),
                const SizedBox(width: 10),
                if (canCreate)
                  InkWell(
                    onTap: () => _openCreateAppointmentDialog(),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff721c80),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(s.add,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    if (view.isWeek) {
      return Scaffold(
        body: Column(
          children: [
            headerAndControls(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildWeekView(
                  workerFilter: workerFilter,
                  canCreate: canCreate,
                  userProv: userProv,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            headerAndControls(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildDayView(
                dayStart: dayStart,
                dayEnd: dayEnd,
                workerFilter: workerFilter,
                userProv: userProv,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Week view ─────────────────────────────────────────────────────────────────

  Widget _buildWeekView({
    required String? workerFilter,
    required bool canCreate,
    required UserProvider userProv,
  }) {
    final weekStart = _startOfWeekMonday(_selectedDay);
    final weekEnd   = _endOfDay(weekStart.add(const Duration(days: 6)));

    Query<Map<String, dynamic>> base = FirebaseFirestore.instance
        .collection('appointments')
        .where('status', isEqualTo: 'scheduled')
        .where('appointmentDate',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(_startOfDay(weekStart)))
        .where('appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(weekEnd));

    if (workerFilter != null && workerFilter.isNotEmpty) {
      base = base.where('workerId', isEqualTo: workerFilter);
    }

    final stream = base.orderBy('appointmentDate').snapshots();
    final colors = _serviceColorsById();

    // El workerId efectivo para los bloques bloqueados es el del filtro actual
    final effectiveWorkerId = workerFilter;

    return WeekCalendarView(
      weekStartMonday: weekStart,
      selectedDay: _selectedDay,
      stream: stream,
      serviceColorById: colors,
      startHour: 7,
      endHour: 21,

      // ── Blocked slots ──────────────────────────────────────────────────────
      blockedSlotRepo: effectiveWorkerId != null ? _blockedSlotRepo : null,
      workerId: effectiveWorkerId,

      onWeekChanged: (newWeekStart) {
        setState(() {
          if (_isCurrentWeek(newWeekStart)) {
            final now = DateTime.now();
            _selectedDay = DateTime(now.year, now.month, now.day);
          } else {
            _selectedDay = DateTime(
                newWeekStart.year, newWeekStart.month, newWeekStart.day);
          }
        });
      },

      onSelectDay: (day) =>
          setState(() => _selectedDay = DateTime(day.year, day.month, day.day)),

      onTapAppointment: (id, data) async {
        final ts  = data['appointmentDate'];
        final dt  = ts is Timestamp ? ts.toDate() : null;
        DateTime dayOnly = _selectedDay;
        if (dt != null) {
          dayOnly = DateTime(dt.year, dt.month, dt.day);
          setState(() => _selectedDay = dayOnly);
        }
        if (dt != null && dt.isBefore(DateTime.now())) {
          await _openPastAppointmentDialog(
              appointmentId: id,
              data: data,
              selectedDayOverride: dayOnly);
          return;
        }
        await _openEditAppointmentDialog(appointmentId: id, data: data);
      },

      onTapEmpty: (day, tod) async {
        if (!canCreate) return;
        final now   = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dd    = DateTime(day.year, day.month, day.day);
        if (dd.isBefore(today)) return;
        if (dd.isAtSameMomentAs(today)) {
          final slot = DateTime(
              day.year, day.month, day.day, tod.hour, tod.minute);
          if (slot.isBefore(now)) return;
        }
        await _openCreateAppointmentDialog(
          preselectedClientId: widget.preselectedClientId,
          initialStartTime: tod,
          selectedDayOverride: day,
        );
      },
    );
  }

  // ── Day view ──────────────────────────────────────────────────────────────────
  //
  // Muestra appointments del día como antes.
  // NUEVO: carga también los blockedSlots del día y los muestra
  // como banners negros con icono de bloqueo en la lista.

  Widget _buildDayView({
    required Timestamp dayStart,
    required Timestamp dayEnd,
    required String? workerFilter,
    required UserProvider userProv,
  }) {
    final dateKey = _yyyymmdd(_selectedDay);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: () {
        final base = FirebaseFirestore.instance
            .collection('appointments')
            .where('status', isEqualTo: 'scheduled')
            .where('appointmentDate', isGreaterThanOrEqualTo: dayStart)
            .where('appointmentDate', isLessThanOrEqualTo: dayEnd);
        final Query<Map<String, dynamic>> q =
            (workerFilter != null && workerFilter.isNotEmpty)
                ? base.where('workerId', isEqualTo: workerFilter)
                : base;
        return q.orderBy('appointmentDate').snapshots();
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child:
                Center(child: CircularProgressIndicator(color: Colors.purple)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // ── Build appointment items ─────────────────────────────────────────
        final items = docs.map((d) {
          final data = d.data();
          final ts   = data['appointmentDate'];
          final start = ts is Timestamp ? ts.toDate() : DateTime.now();
          final dur   = data['durationMin'] is num
              ? (data['durationMin'] as num).toInt()
              : 0;
          final safeDur = dur <= 0 ? 0 : dur;
          return _ApptVM(
            id:          d.id,
            doc:         d,
            data:        data,
            start:       start,
            end:         start.add(Duration(minutes: safeDur)),
            durationMin: safeDur,
          );
        }).toList();

        for (final a in items) {
          int maxOverlap = 0;
          for (final b in items) {
            if (a.id == b.id) continue;
            final overlap =
                _minutesOverlap(a.start, a.end, b.start, b.end);
            if (overlap > maxOverlap) maxOverlap = overlap;
          }
          a.maxOverlapMin = maxOverlap;
          a.dotColor = _conflictColorFromMaxOverlap(maxOverlap);
        }

        // ── Blocked slots for this day (FutureBuilder) ──────────────────────
        return FutureBuilder<List<BlockedSlot>>(
          future: (workerFilter != null && workerFilter.isNotEmpty)
              ? _blockedSlotRepo.fetchForDay(workerFilter, dateKey)
              : Future.value(const []),
          builder: (context, blockedSnap) {
            final blocked = blockedSnap.data ?? const [];

            if (docs.isEmpty && blocked.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Text('No appointments for this day',
                    style: TextStyle(color: Colors.grey[700])),
              );
            }

            // Merge: appointments + blocked → ordenar por hora
            // Usamos un tipo unificado para ordenar
            final merged = <_DayItem>[];

            for (final vm in items) {
              merged.add(_DayItem.appt(vm));
            }
            for (final bs in blocked) {
              merged.add(_DayItem.blocked(bs));
            }
            merged.sort((a, b) => a.startMin.compareTo(b.startMin));

            return Column(
              children: merged.map((item) {
                if (item.blockedSlot != null) {
                  return _BlockedSlotDayTile(
                    slot: item.blockedSlot!,
                    onManage: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => BlockSlotDialog(
                          workerId: workerFilter!,
                          date: _selectedDay,
                          repo: _blockedSlotRepo,
                          initialStartMin: item.blockedSlot!.startMin,
                          initialEndMin: item.blockedSlot!.endMin,
                        ),
                      );
                      setState(() {}); // refresh FutureBuilder
                    },
                  );
                }

                final vm = item.vm!;
                return _AdminAppointmentTile(
                  doc: vm.doc,
                  dotColor: vm.dotColor ?? Colors.green,
                  onTap: () async {
                    final ts = vm.data['appointmentDate'];
                    final dt = ts is Timestamp ? ts.toDate() : null;
                    if (dt != null && dt.isBefore(DateTime.now())) {
                      final dayOnly = DateTime(dt.year, dt.month, dt.day);
                      setState(() => _selectedDay = dayOnly);
                      await _openPastAppointmentDialog(
                          appointmentId: vm.id,
                          data: vm.data,
                          selectedDayOverride: dayOnly);
                      return;
                    }
                    await _openEditAppointmentDialog(
                        appointmentId: vm.id, data: vm.data);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ── Day item (merge helper) ───────────────────────────────────────────────────

class _DayItem {
  final _ApptVM? vm;
  final BlockedSlot? blockedSlot;
  final int startMin;

  _DayItem.appt(_ApptVM v)
      : vm = v,
        blockedSlot = null,
        startMin = v.start.hour * 60 + v.start.minute;

  _DayItem.blocked(BlockedSlot s)
      : blockedSlot = s,
        vm = null,
        startMin = s.startMin;
}

// ── Blocked slot day tile ─────────────────────────────────────────────────────

class _BlockedSlotDayTile extends StatelessWidget {
  const _BlockedSlotDayTile(
      {required this.slot, required this.onManage});
  final BlockedSlot slot;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final startStr = DateTimeUtils.hhmmFromMinutes(slot.startMin);
    final endStr   = DateTimeUtils.hhmmFromMinutes(slot.endMin);

    return InkWell(
      onTap: onManage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.block, color: Colors.black54, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blocked  $startStr – $endStr',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  if (slot.reason.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(slot.reason,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

// ── _ApptVM ───────────────────────────────────────────────────────────────────

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

// ── _AdminAppointmentTile (idéntico al original) ──────────────────────────────

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
    final data       = doc.data() as Map<String, dynamic>? ?? {};
    final isPending  = PendingConfirmationUtils.isPending(data);
    final dt         = _ts(data, 'appointmentDate');
    final durationMin = _i(data, 'durationMin');
    final safeDur    = durationMin <= 0 ? 0 : durationMin;

    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final startText  = dt == null ? '--:--' : fmt(dt);
    final endText    = dt == null
        ? '--:--'
        : fmt(dt.add(Duration(minutes: safeDur)));

    final key        = _s(data, 'serviceNameKey', '');
    final serviceName = key.isNotEmpty
        ? trServiceOrAddon(context, key)
        : _s(data, 'serviceName', 'Service');
    final clientName = _s(data, 'clientName', 'Client');

    final ctry = data['clientCountry'];
    final ph   = data['clientPhone'];
    final phoneText = (ctry is num && ph is num && ctry > 0 && ph > 0)
        ? '+${ctry.toInt()} ${ph.toInt()}'
        : '';
    final ig    = _s(data, 'clientInstagram', '');
    final total = _n(data, 'total');

    final contact = [
      if (phoneText.isNotEmpty) phoneText,
      if (ig.isNotEmpty) '@$ig',
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isPending
              ? PendingConfirmationUtils.pendingCardBg
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPending
                ? PendingConfirmationUtils.pendingColor.withOpacity(0.40)
                : const Color(0xff721c80).withOpacity(0.15),
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
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
                    Text(startText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xff721c80),
                            fontSize: 13,
                            height: 1.0)),
                    const SizedBox(height: 2),
                    Text(endText,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xff721c80),
                            fontSize: 12,
                            height: 1.0)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: PendingConfirmationUtils.pendingColor
                            .withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Pending confirmation',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87)),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    contact.isEmpty ? clientName : '$clientName • $contact',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (durationMin > 0) ...[
                    const SizedBox(height: 2),
                    Text('${durationMin}m',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total > 0 ? '€${total.toStringAsFixed(0)}' : '',
              style: const TextStyle(
                  color: Color(0xff721c80), fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
