import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/components/ui/app_icon_value_pill_button.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_preview_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';

import 'package:salon_app/widgets/booking_request_card.dart';
import 'package:salon_app/widgets/booking_request_create_form.dart';
import 'package:salon_app/widgets/async_optimistic_switch.dart';

import 'package:salon_app/repositories/booking_request_repo.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

enum HomeAdminMode { looking, cancelled, noShow }

class HomeClientBottomSheet extends StatefulWidget {
  const HomeClientBottomSheet({
    super.key,
    required this.clientId,
    required this.mode,
  });

  final String clientId;
  final HomeAdminMode mode;

  @override
  State<HomeClientBottomSheet> createState() => _HomeClientBottomSheetState();
}

class _HomeClientBottomSheetState extends State<HomeClientBottomSheet> {
  late final BookingRequestRepo brRepo;

  bool _creatingRequest = false;

  // multi-day + multi-range
  final List<String> _selectedDayKeys = <String>[]; // yyyymmdd
  final List<Map<String, int>> _selectedRanges = <Map<String, int>>[]; // {startMin,endMin}

  String? _selectedWorkerId; // null => any worker
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedServiceData;
  int _selectedDurationMin = 30;

  static const Color kPurple = Color(0xff721c80);

  // Business hours (requested): 07:00 - 21:00
  static const int _bizStartMin = 7 * 60;
  static const int _bizEndMax = 21 * 60;
  static const int _minRangeLen = 15;      // mínimo 15 min

  // Pickers clamp (keep sane values)
  static const int _startMinClamp = _bizStartMin; // 07:00
  static const int _startMaxClamp = 20 * 60; // latest "start" pick; real latest depends on duration
  static const int _endMinClamp = 7 * 60 + 30; // 07:30 (UI convenience)
  static const int _endMaxClamp = _bizEndMax; // 21:00

  Future<List<String>>? _workersFuture;
  List<String> _workerIdsCache = const [];
  
  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMin(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23);
    final m = (minutes % 60).clamp(0, 59);
    return TimeOfDay(hour: h, minute: m);
  }

  TimeOfDay _clampTime(TimeOfDay t, int min, int max) {
    final v = _toMin(t);
    final clamped = v.clamp(min, max);
    return _fromMin(clamped);
  }

  // ===================== Range rules (Booking Requests) =====================

  int _roundUpToStep(int minutes, int step) {
    if (step <= 1) return minutes;
    final r = minutes % step;
    return r == 0 ? minutes : minutes + (step - r);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _nowMinRounded({required int step}) {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    return _roundUpToStep(m, step);
  }

  /// Start initial:
  /// - por defecto 07:00
  /// - si hoy, entonces max(07:00, ahora redondeado)
  TimeOfDay _initialStartTimeForRange() {
    int startMin = _bizStartMin;

    // si hoy: no permitir empezar antes de ahora
    final today = DateTime.now();
    // OJO: si tu booking request NO tiene días seleccionados aún, lo tratamos como "hoy" para UX.
    // Si YA hay días seleccionados y NO incluye hoy, entonces usamos 07:00.
    final hasTodaySelected = _selectedDayKeys.any((k) {
      final dt = BookingRequestUtils.parseYyyymmdd(k);
      return dt != null && _isSameDay(dt, today);
    });

    if (hasTodaySelected) {
      final nowMin = _nowMinRounded(step: 5);
      startMin = startMin < nowMin ? nowMin : startMin;
    }

    // si ya son más de 21:00, igual dejaremos 21:00 (pero luego no podrás crear rango)
    if (startMin > _bizEndMax - _minRangeLen) {
      startMin = _bizEndMax - _minRangeLen;
    }

    return _fromMin(startMin);
  }

  /// End initial siempre = start + 15
  TimeOfDay _initialEndFromStart(TimeOfDay start) {
    final s = _toMin(start);
    final e = (s + _minRangeLen).clamp(_bizStartMin + _minRangeLen, _bizEndMax);
    return _fromMin(e);
  }

  /// Ajusta start/end a reglas:
  /// - start >= 07:00
  /// - end <= 21:00
  /// - end >= start + 15
  ({TimeOfDay start, TimeOfDay end}) _sanitizeRange(TimeOfDay start, TimeOfDay end) {
    int s = _toMin(start);
    int e = _toMin(end);

    if (s < _bizStartMin) s = _bizStartMin;
    if (e > _bizEndMax) e = _bizEndMax;

    // end mínimo 15 min después
    final minEnd = s + _minRangeLen;
    if (e < minEnd) e = minEnd;

    // si por límite 21:00 se rompe, empuja start hacia atrás
    if (e > _bizEndMax) e = _bizEndMax;
    if (s > _bizEndMax - _minRangeLen) s = _bizEndMax - _minRangeLen;

    // vuelve a asegurar minEnd tras mover start
    final minEnd2 = s + _minRangeLen;
    if (e < minEnd2) e = minEnd2;
    if (e > _bizEndMax) e = _bizEndMax;

    return (start: _fromMin(s), end: _fromMin(e));
  }

  /// Comprueba si un rango (en minutos) puede contener un procedimiento de durationMin
  bool _rangeFitsDuration(Map<String, int> r, int durationMin) {
    final s = r['startMin'] ?? 0;
    final e = r['endMin'] ?? 0;
    return (e - s) >= durationMin;
  }

  Future<void> _showRangeStepOverlay({
    required String title,
    required String subtitle,
  }) async {
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "range_step",
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 1,
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: kPurple.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPurple.withOpacity(0.25)),
                        ),
                        child: Icon(Icons.check, color: kPurple),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(kPurple.withOpacity(0.85)),
                      backgroundColor: Colors.black.withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, a2, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  void _showStepHint(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  String _fmtDdMm(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  String _fmtDdMmYyyy(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  String _fmtHm(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  Future<void> _addDay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      initialDate: today,
    );
    if (picked == null) return;
    final key = BookingRequestUtils.yyyymmdd(picked);
    setState(() {
      if (!_selectedDayKeys.contains(key)) _selectedDayKeys.add(key);
      _selectedDayKeys.sort();
    });
  }

  void _removeDayKey(String key) {
    setState(() => _selectedDayKeys.remove(key));
  }

  Future<void> _addRange() async {
    // 1) START picker: por defecto 07:00 (o ahora si HOY está seleccionado)
    final startPicked = await showTimePicker(
      context: context,
      initialTime: _initialStartTimeForRange(),
    );
    if (startPicked == null) return;

    // Clamp start a 07:00..(21:00-15)
    TimeOfDay start = startPicked;
    final sMin = _toMin(start);
    final clampedSMin = sMin.clamp(_bizStartMin, _bizEndMax - _minRangeLen);
    start = _fromMin(clampedSMin);

    // ✅ Overlay bonito entre pasos (se cierra solo)
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.selectionClick();

    final startLabel = BookingRequestUtils.hhmm(start);

    // auto-close overlay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });

    await _showRangeStepOverlay(
      title: "Inicio guardado: $startLabel",
      subtitle: "Ahora selecciona el fin",
    );

    await Future.delayed(const Duration(milliseconds: 120));

    // 2) END picker: preseleccionado start + 15
    final endPicked = await showTimePicker(
      context: context,
      initialTime: _initialEndFromStart(start),
    );
    if (endPicked == null) return;

    // Sanitizar rango a reglas
    final fixed = _sanitizeRange(start, endPicked);
    final startFixed = fixed.start;
    final endFixed = fixed.end;

    final range = BookingRequestUtils.range(startFixed, endFixed);

    // ✅ Si hay procedimiento seleccionado, verificar que cabe
    final durationMin = _selectedDurationMin > 0 ? _selectedDurationMin : 30;

    if (!_rangeFitsDuration(range, durationMin)) {
      await showDialog<void>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text("Rango demasiado pequeño"),
          content: Text("Este procedimiento necesita ${durationMin} min. Ajusta el fin del rango."),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _selectedRanges.add(range);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Rango añadido: ${BookingRequestUtils.hhmm(startFixed)}–${BookingRequestUtils.hhmm(endFixed)}",
        ),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
  void _removeRangeAt(int i) {
    if (i < 0 || i >= _selectedRanges.length) return;
    setState(() => _selectedRanges.removeAt(i));
  }

  @override
  void initState() {
    super.initState();
    brRepo = BookingRequestRepo(FirebaseFirestore.instance);

    _workersFuture = _getAllWorkerIds().then((ids) {
      _workerIdsCache = ids;
      return ids;
    });

    // limpieza automática al abrir (expiradas)
    brRepo.pruneExpiredActiveRequests(clientId: widget.clientId);
    
  }

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

  Color _modeTint(HomeAdminMode m) {
    switch (m) {
      case HomeAdminMode.looking:
        return kPurple;
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

  // ===================== Availability helpers =====================

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endExclusive(DateTime d) => DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  static const int kStepMin = 5;

  int _requestedDurationMin(Map<String, dynamic> br) {
    final v = br['durationMin'];
    if (v is num) return v.toInt();
    return 30;
  }

  int _allowedOverlapMin(int durMin) => (durMin > 60) ? 15 : 0;

  int _overlapMin(int a0, int a1, int b0, int b1) {
    final s = a0 > b0 ? a0 : b0;
    final e = a1 < b1 ? a1 : b1;
    return (e > s) ? (e - s) : 0;
  }

  bool _slotOkForWorkerWithTolerance({
    required DateTime day,
    required int startMin,
    required int durMin,
    required String workerId,
    required int allowedOverlap,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    final endMin = startMin + durMin;

    for (final a in appts) {
      final data = a.data();
      if ((data['status'] ?? '').toString() != 'scheduled') continue;
      if ((data['workerId'] ?? '').toString().trim() != workerId) continue;

      final ts = data['appointmentDate'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();

      if (dt.year != day.year || dt.month != day.month || dt.day != day.day) continue;

      final adur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 0;
      if (adur <= 0) continue;

      final a0 = dt.hour * 60 + dt.minute;
      final a1 = a0 + adur;

      final ov = _overlapMin(startMin, endMin, a0, a1);
      if (ov > allowedOverlap) return false;
    }

    return true;
  }

  /// ✅ Important: returns first start that fits COMPLETELY inside each range
  /// AND fits inside business hours 07:00-21:00
  DateTime? _firstSlotOnDayForWorker({
    required DateTime day,
    required List<Map<String, int>> ranges,
    required int durMin,
    required String workerId,
    required int allowedOverlap,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    for (final r in ranges) {
      final rawStart = r['startMin'] ?? 0;
      final rawEnd = r['endMin'] ?? (24 * 60);

      // clamp to business hours
      final rs = rawStart < _bizStartMin ? _bizStartMin : rawStart;
      final re = rawEnd > _bizEndMax ? _bizEndMax : rawEnd;

      // if range can't fit the full procedure, skip
      if (re - rs < durMin) continue;

      for (int s = rs; s + durMin <= re; s += kStepMin) {
        final ok = _slotOkForWorkerWithTolerance(
          day: day,
          startMin: s,
          durMin: durMin,
          workerId: workerId,
          allowedOverlap: allowedOverlap,
          appts: appts,
        );
        if (ok) {
          return DateTime(day.year, day.month, day.day, s ~/ 60, s % 60);
        }
      }
    }
    return null;
  }

  List<Map<String, int>> _extractRanges(Map<String, dynamic> br) {
    final raw = (br['preferredTimeRanges'] as List?) ?? const [];
    if (raw.isEmpty) return const [{'startMin': 0, 'endMin': 24 * 60}];

    final out = <Map<String, int>>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final m = Map<String, dynamic>.from(r);

      final s = (m['startMin'] ?? m['start']);
      final e = (m['endMin'] ?? m['end']);

      final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? -1;
      final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? -1;
      if (sm >= 0 && em > sm) out.add({'startMin': sm, 'endMin': em});
    }

    if (out.isEmpty) return const [{'startMin': 0, 'endMin': 24 * 60}];
    return out;
  }

  Future<List<String>> _getAllWorkerIds() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('workers').get();
      return snap.docs.map((d) => d.id).where((id) => id.trim().isNotEmpty).toList();
    } catch (_) {
      return const <String>[];
    }
  }

  ({BookingRequestAvailability status, DateTime? nextStart}) _availabilityInfoForRequest({
    required Map<String, dynamic> br,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    final workerIdRaw = (br['workerId'] ?? '').toString().trim();
    final isAnyWorker = workerIdRaw.isEmpty;

    final preferredDays = (br['preferredDays'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final exactSlots = (br['exactSlots'] as List?) ?? const [];
    final ranges = _extractRanges(br);

    final durMin = _requestedDurationMin(br);
    final allowedOverlap = _allowedOverlapMin(durMin);

    if (preferredDays.isEmpty && exactSlots.isEmpty) {
      return (status: BookingRequestAvailability.unknown, nextStart: null);
    }

    // Parse preferred days sorted
    final parsedDays = preferredDays
        .map((k) => BookingRequestUtils.parseYyyymmdd(k))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    // ─────────────────────────────────────────────────────────────
    // EXACT SLOTS
    // ─────────────────────────────────────────────────────────────
    if (!isAnyWorker) {
      // Exact slots for a fixed worker
      for (final x in exactSlots) {
        if (x is! Timestamp) continue;
        final dt = x.toDate();
        final day = DateTime(dt.year, dt.month, dt.day);
        final sMin = dt.hour * 60 + dt.minute;

        final ok = _slotOkForWorkerWithTolerance(
          day: day,
          startMin: sMin,
          durMin: durMin,
          workerId: workerIdRaw,
          allowedOverlap: allowedOverlap,
          appts: appts,
        );
        if (ok) return (status: BookingRequestAvailability.available, nextStart: dt);
      }
    } else {
      // Any worker: we can’t decide sync without workers list -> return checking here,
      // but we'll compute async via FutureBuilder in the UI (next section).
      return (status: BookingRequestAvailability.unknown, nextStart: null);
    }

    // ─────────────────────────────────────────────────────────────
    // PREFERRED DAYS
    // ─────────────────────────────────────────────────────────────
    if (!isAnyWorker) {
      for (final day in parsedDays) {
        final first = _firstSlotOnDayForWorker(
          day: day,
          ranges: ranges,
          durMin: durMin,
          workerId: workerIdRaw,
          allowedOverlap: allowedOverlap,
          appts: appts,
        );
        if (first != null) {
          return (status: BookingRequestAvailability.available, nextStart: first);
        }
      }

      return (status: BookingRequestAvailability.unavailable, nextStart: null);
    }

    // Any worker already returned unknown above
    return (status: BookingRequestAvailability.unknown, nextStart: null);
  }

  String _pillLabelForRequest(BookingRequestAvailability status, DateTime? nextStart) {
    if (status == BookingRequestAvailability.unknown) return "Checking…";
    if (status == BookingRequestAvailability.unavailable) return "No availability";
    if (nextStart == null) return " ";

    final hm = _fmtHm(nextStart);
    final ddmm = _fmtDdMm(nextStart);
    return "$hm - $ddmm";
  }

  // ===================== Validations =====================

  bool _rangesFitDuration(List<Map<String, int>> ranges, int durMin) {
    if (ranges.isEmpty) return true; // allow empty => "any time"
    for (final r in ranges) {
      final s = r['startMin'] ?? 0;
      final e = r['endMin'] ?? 0;
      if (e - s < durMin) return false;
    }
    return true;
  }

  // ===================== Create request =====================

  Future<void> _createRequest() async {
    if (_selectedServiceId == null || _selectedServiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a procedure first")),
      );
      return;
    }

    final preferredDays = List<String>.from(_selectedDayKeys);
    final ranges = List<Map<String, int>>.from(_selectedRanges);

    if (_selectedServiceData == null) {
      final doc = await FirebaseFirestore.instance.collection('services').doc(_selectedServiceId!).get();
      _selectedServiceData = doc.data();
    }

    final svc = _selectedServiceData ?? const <String, dynamic>{};
    final nameKey = (svc['name'] ?? '').toString();
    final label = nameKey.isNotEmpty ? nameKey : _selectedServiceId!;
    final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : _selectedDurationMin;

    // ✅ NEW: validate ranges >= duration
    if (!_rangesFitDuration(ranges, dur)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected time range must be at least $dur min")),
      );
      return;
    }

    // ✅ NEW: if future appointment exists with same category, show first date/time and confirm
    final selectedCategory = (svc['category'] ?? 'hands').toString();
    try {
      final now = Timestamp.now();
      final apptsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .where('status', isEqualTo: 'scheduled')
          .where('appointmentDate', isGreaterThanOrEqualTo: now)
          .orderBy('appointmentDate')
          .limit(25)
          .get();

      DateTime? firstSameCat;
      final cache = <String, String>{};

      for (final a in apptsSnap.docs) {
        final data = a.data();
        final sid = (data['serviceId'] ?? '').toString();
        if (sid.isEmpty) continue;

        final cat = cache[sid] ??
            ((await FirebaseFirestore.instance.collection('services').doc(sid).get()).data()?['category'] ?? 'hands')
                .toString();
        cache[sid] = cat;

        if (cat == selectedCategory) {
          final ts = data['appointmentDate'];
          if (ts is Timestamp) {
            firstSameCat = ts.toDate();
          }
          break;
        }
      }

      if (firstSameCat != null) {
        final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Appointment already exists'),
                  content: Text(
                    "This client already has a scheduled appointment for '$selectedCategory': "
                    "${_fmtHm(firstSameCat!)} • ${_fmtDdMmYyyy(firstSameCat)}\n\n"
                    "Create a booking request anyway?",
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
                  ],
                );
              },
            ) ??
            false;

        if (!ok) return;
      }
    } catch (_) {}

    final durationMin = _selectedDurationMin > 0 ? _selectedDurationMin : 30;
    final badRanges = _selectedRanges.where((r) => !_rangeFitsDuration(r, durationMin)).toList();
    if (badRanges.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⛔ Ajusta los rangos: necesitan ≥ ${durationMin} min para este procedimiento")),
      );
      return;
    }

    await brRepo.upsertRequest(
      clientId: widget.clientId,
      workerId: _selectedWorkerId,
      serviceId: _selectedServiceId!,
      serviceNameKey: nameKey,
      serviceNameLabel: label,
      durationMin: dur,
      exactSlots: const [],
      preferredDays: preferredDays,
      preferredTimeRanges: ranges,
    );

    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
      "bookingRequestActive": true,
      "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _creatingRequest = false;
      _selectedDayKeys.clear();
      _selectedRanges.clear();
      _selectedWorkerId = null;

      _selectedServiceId = null;
      _selectedServiceData = null;
      _selectedDurationMin = 30;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking request created")),
    );
  }

  // ===================== Disable looking =====================

  Future<void> _confirmAndDisableLooking() async {
    final docs = await brRepo.getActiveRequestsForClient(widget.clientId);

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Disable booking requests?"),
        content: Text(
          docs.isEmpty
              ? "This will disable 'Looking for appointment'. Continue?"
              : "This will delete ALL active booking requests (${docs.length}) and disable the switch. Continue?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (docs.isNotEmpty) {
      await brRepo.deleteAllActiveForClient(widget.clientId);
    }

    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
      "bookingRequestActive": false,
      "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _creatingRequest = false);
  }

  Widget _openInClientsButton() {
    return AppIconValuePillButton(
      color: kPurple,
      icon: Icons.open_in_new_rounded,
      label: "Open in Clients",
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      fillOpacity: 0.12,
      borderOpacity: 0.28,
      shadow: false,
      onTap: () {
        context.read<AdminNavProvider>().goToClientsAndOpen(widget.clientId);
        Navigator.pop(context);
      },
    );
  }

  // ===================== EDIT REQUEST (procedure + worker + day + range) =====================

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
            .toList() ??
        <String>[];

    final rangeList = <Map<String, int>>[];
    final rawRanges = (br['preferredTimeRanges'] as List?) ?? const [];
    for (final rr in rawRanges) {
      if (rr is! Map) continue;
      final m = Map<String, dynamic>.from(rr);
      final s = (m['startMin'] ?? m['start']);
      final e = (m['endMin'] ?? m['end']);
      final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? -1;
      final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? -1;
      if (sm >= 0 && em > sm) {
        rangeList.add({'startMin': sm, 'endMin': em});
      }
    }

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> save() async {
              if (saving) return;

              if (serviceId == null || serviceId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Select a procedure first")),
                );
                return;
              }

              setLocal(() => saving = true);
              try {
                final svcDoc = await FirebaseFirestore.instance.collection('services').doc(serviceId!).get();
                final svc = svcDoc.data() ?? const <String, dynamic>{};

                final nameKey = (svc['name'] ?? '').toString();
                final label = nameKey.isNotEmpty ? nameKey : serviceId!;
                final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : 30;

                final preferredDays = List<String>.from(dayKeys);
                final preferredRanges = List<Map<String, int>>.from(rangeList);

                // ✅ NEW: validate ranges >= duration
                if (!_rangesFitDuration(preferredRanges, dur)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Selected time range must be at least $dur min")),
                  );
                  return;
                }

                await brRepo.updateRequest(
                  requestId: requestId,
                  workerId: workerId,
                  serviceId: serviceId!,
                  serviceNameKey: nameKey,
                  serviceNameLabel: label,
                  durationMin: dur,
                  preferredDays: preferredDays,
                  preferredTimeRanges: preferredRanges,
                );

                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request updated")),
                );
              } finally {
                if (ctx.mounted) setLocal(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 16 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Edit request",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  BookingRequestCreateForm(
                    selectedWorkerId: workerId,
                    onWorkerChanged: (v) => setLocal(() => workerId = v),

                    selectedServiceId: serviceId,
                    onServiceChanged: (newServiceId) async {
                      if (newServiceId == null || newServiceId.isEmpty) {
                        setLocal(() {
                          serviceId = null;
                        });
                        return;
                      }

                      // ✅ NUNCA desmarcar procedimiento: siempre se aplica
                      setLocal(() => serviceId = newServiceId);

                      // Cargar duración del procedimiento para validar rangos
                      int dur = 30;
                      try {
                        final doc = await FirebaseFirestore.instance
                            .collection('services')
                            .doc(newServiceId)
                            .get();
                        final data = doc.data() ?? const <String, dynamic>{};
                        dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 30;
                      } catch (_) {}

                      // 🔎 detectar rangos que no caben
                      final badIdx = <int>[];
                      for (int i = 0; i < rangeList.length; i++) {
                        final r = rangeList[i];
                        final s = r['startMin'] ?? 0;
                        final e = r['endMin'] ?? 0;
                        if ((e - s) < dur) badIdx.add(i);
                      }

                      if (badIdx.isEmpty || !ctx.mounted) return;

                      await showDialog<void>(
                        context: ctx,
                        builder: (dctx) => AlertDialog(
                          title: const Text("Rangos demasiado pequeños"),
                          content: Text(
                            "Este procedimiento necesita ${dur} min.\n\n"
                            "Se eliminarán ${badIdx.length} rango(s) que no tienen suficiente tiempo.",
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dctx),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );

                      setLocal(() {
                        for (final i in badIdx.reversed) {
                          rangeList.removeAt(i);
                        }
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Se eliminaron rangos incompatibles (mínimo ${dur} min).")),
                      );
                    },

                    selectedDays: dayKeys,
                    selectedRanges: rangeList,

                    onAddDay: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: today,
                        lastDate: DateTime(now.year + 2),
                        initialDate: today,
                      );
                      if (picked == null) return;
                      final key = BookingRequestUtils.yyyymmdd(picked);
                      setLocal(() {
                        if (!dayKeys.contains(key)) dayKeys.add(key);
                        dayKeys.sort();
                      });
                    },

                    onRemoveDayKey: (k) => setLocal(() => dayKeys.remove(k)),

                    onAddRange: () async {
                      // 1) START: 07:00 (o ahora si HOY está entre dayKeys)
                      TimeOfDay initialStart() {
                        int startMin = _bizStartMin; // 07:00

                        final today = DateTime.now();
                        final hasTodaySelected = dayKeys.any((k) {
                          final dt = BookingRequestUtils.parseYyyymmdd(k);
                          return dt != null && _isSameDay(dt, today);
                        });

                        if (hasTodaySelected) {
                          final nowMin = _nowMinRounded(step: 5);
                          if (startMin < nowMin) startMin = nowMin;
                        }

                        if (startMin > _bizEndMax - _minRangeLen) {
                          startMin = _bizEndMax - _minRangeLen;
                        }

                        return _fromMin(startMin);
                      }

                      final startPicked = await showTimePicker(
                        context: ctx,
                        initialTime: initialStart(),
                      );
                      if (startPicked == null) return;

                      // clamp start a 07:00..(21:00-15)
                      TimeOfDay start = startPicked;
                      final sMin = _toMin(start);
                      final clampedSMin = sMin.clamp(_bizStartMin, _bizEndMax - _minRangeLen);
                      start = _fromMin(clampedSMin);

                      // overlay bonito entre pasos
                      await Future.delayed(const Duration(milliseconds: 80));
                      HapticFeedback.selectionClick();

                      final startLabel = BookingRequestUtils.hhmm(start);

                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
                      });

                      await _showRangeStepOverlay(
                        title: "Inicio guardado: $startLabel",
                        subtitle: "Ahora selecciona el fin",
                      );

                      await Future.delayed(const Duration(milliseconds: 120));

                      // 2) END: start + 15
                      final endPicked = await showTimePicker(
                        context: ctx,
                        initialTime: _initialEndFromStart(start),
                      );
                      if (endPicked == null) return;

                      final fixed = _sanitizeRange(start, endPicked);
                      final startFixed = fixed.start;
                      final endFixed = fixed.end;

                      final range = BookingRequestUtils.range(startFixed, endFixed);

                      // ✅ Validar duración del procedimiento si hay serviceId seleccionado
                      int dur = 30;
                      if (serviceId != null && serviceId!.isNotEmpty) {
                        try {
                          final doc = await FirebaseFirestore.instance
                              .collection('services')
                              .doc(serviceId!)
                              .get();
                          final data = doc.data() ?? const <String, dynamic>{};
                          dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 30;
                        } catch (_) {}
                      }

                      final rs = range['startMin'] ?? 0;
                      final re = range['endMin'] ?? 0;

                      if ((re - rs) < dur) {
                        await showDialog<void>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text("Rango demasiado pequeño"),
                            content: Text("Este procedimiento necesita ${dur} min. Ajusta el fin del rango."),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dctx),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      setLocal(() => rangeList.add(range));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "✅ Rango añadido: ${BookingRequestUtils.hhmm(startFixed)}–${BookingRequestUtils.hhmm(endFixed)}",
                          ),
                          duration: const Duration(milliseconds: 900),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      );
                    },

                    onRemoveRangeAt: (i) {
                      if (i < 0 || i >= rangeList.length) return;
                      setLocal(() => rangeList.removeAt(i));
                    },

                    onCreate: save,
                    purple: kPurple,
                  ),
                  const SizedBox(height: 10),
                  if (saving) const CircularProgressIndicator(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===================== UI: request tile =====================

  Widget _requestTile({
    required String requestId,
    required Map<String, dynamic> br,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appointmentsDocs,
  }) {
    final workerIdRaw = (br['workerId'] ?? '').toString().trim();
    final isAnyWorker = workerIdRaw.isEmpty;

    if (!isAnyWorker) {
      final info = _availabilityInfoForRequest(br: br, appts: appointmentsDocs);
      final label = _pillLabelForRequest(info.status, info.nextStart);

      return BookingRequestCard(
        requestId: requestId,
        br: br,
        purple: kPurple,
        availability: info.status,
        availabilityLabel: label,
        onDelete: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text("Delete request?"),
              content: const Text("This will delete this booking request."),
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
          await brRepo.deleteRequest(requestId);
        },
        onEditRequest: () => _editRequestSheet(requestId: requestId, br: br),
      );
    }

    // ✅ Any worker: compute earliest slot across all workers (async)
    return FutureBuilder<List<String>>(
      future: _workersFuture,
      builder: (context, wsnap) {
        final workerIds = _workerIdsCache.isNotEmpty ? _workerIdsCache : (wsnap.data ?? const <String>[]);

        // still loading workers
        if (workerIds.isEmpty && wsnap.connectionState != ConnectionState.done) {
          return BookingRequestCard(
            requestId: requestId,
            br: br,
            purple: kPurple,
            availability: BookingRequestAvailability.unknown,
            availabilityLabel: "Checking…",
            onDelete: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text("Delete request?"),
                  content: const Text("This will delete this booking request."),
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
              await brRepo.deleteRequest(requestId);
            },
            onEditRequest: () => _editRequestSheet(requestId: requestId, br: br),
          );
        }

        if (workerIds.isEmpty) {
          // no workers found -> can't compute
          return BookingRequestCard(
            requestId: requestId,
            br: br,
            purple: kPurple,
            availability: BookingRequestAvailability.unknown,
            availabilityLabel: "No workers",
            onDelete: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text("Delete request?"),
                  content: const Text("This will delete this booking request."),
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
              await brRepo.deleteRequest(requestId);
            },
            onEditRequest: () => _editRequestSheet(requestId: requestId, br: br),
          );
        }

        // compute earliest among workers
        DateTime? best;
        final ranges = _extractRanges(br);
        final preferredDays = (br['preferredDays'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList() ??
            const <String>[];

        final parsedDays = preferredDays
            .map((k) => BookingRequestUtils.parseYyyymmdd(k))
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => a.compareTo(b));

        final durMin = _requestedDurationMin(br);
        final allowedOverlap = _allowedOverlapMin(durMin);

        for (final day in parsedDays) {
          for (final wid in workerIds) {
            final first = _firstSlotOnDayForWorker(
              day: day,
              ranges: ranges,
              durMin: durMin,
              workerId: wid,
              allowedOverlap: allowedOverlap,
              appts: appointmentsDocs,
            );
            if (first != null) {
              if (best == null || first.isBefore(best)) best = first;
            }
          }
          if (best != null) break; // earliest day already has a slot
        }

        final status = (best == null)
            ? BookingRequestAvailability.unavailable
            : BookingRequestAvailability.available;

        final label = _pillLabelForRequest(status, best);

        return BookingRequestCard(
          requestId: requestId,
          br: br,
          purple: kPurple,
          availability: status,
          availabilityLabel: label,
          onDelete: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (dctx) => AlertDialog(
                title: const Text("Delete request?"),
                content: const Text("This will delete this booking request."),
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
            await brRepo.deleteRequest(requestId);
          },
          onEditRequest: () => _editRequestSheet(requestId: requestId, br: br),
        );
      },
    );
  }

  Widget _activeRequestsSection({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appointmentsDocs,
  }) {
    if (docs.isEmpty) {
      return AppSectionCard(
        title: "Active booking requests",
        child: Text(
          "No active booking requests yet.",
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final mustScrollInside = docs.length > 2;

    if (!mustScrollInside) {
      return AppSectionCard(
        title: "Active booking requests",
        child: Column(
          children: [
            for (int i = 0; i < docs.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _requestTile(
                requestId: docs[i].id,
                appointmentsDocs: appointmentsDocs,
                br: docs[i].data(),
              ),
            ],
          ],
        ),
      );
    }

    const double maxPanelH = 280;
    return AppSectionCard(
      title: "Active booking requests",
      child: SizedBox(
        height: maxPanelH,
        child: ListView.separated(
          key: PageStorageKey("home_active_requests_${widget.clientId}"),
          padding: const EdgeInsets.only(top: 3, bottom: 3),
          physics: const ClampingScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final d = docs[i];
            return _requestTile(
              requestId: d.id,
              appointmentsDocs: appointmentsDocs,
              br: d.data(),
            );
          },
        ),
      ),
    );
  }

  Widget _lookingBody({
    required Map<String, dynamic> client,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activeRequestDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appointmentsDocs,
  }) {
    final looking = client['bookingRequestActive'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionCard(
          title: "Booking request",
          child: Row(
            children: [
              Expanded(
                child: Text(
                  looking ? "Looking for appointment" : "Not looking",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              AsyncOptimisticSwitch(
                value: looking,
                switchActiveColor: kPurple,
                onSave: (v) async {
                  if (!v) {
                    await _confirmAndDisableLooking();
                    return;
                  }
                  await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
                    "bookingRequestActive": true,
                    "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _openInClientsButton()),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() => _creatingRequest = !_creatingRequest),
                icon: Icon(_creatingRequest ? Icons.expand_less : Icons.add, color: Colors.white),
                label: Text(
                  _creatingRequest ? "Hide" : "Create request",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        if (_creatingRequest) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            title: "New request details",
            child: BookingRequestCreateForm(
              selectedWorkerId: _selectedWorkerId,
              onWorkerChanged: (v) => setState(() => _selectedWorkerId = v),

              selectedServiceId: _selectedServiceId,
              onServiceChanged: (serviceId) async {
                if (serviceId == null || serviceId.isEmpty) {
                  setState(() {
                    _selectedServiceId = null;
                    _selectedServiceData = null;
                    _selectedDurationMin = 30;
                  });
                  return;
                }

                final doc = await FirebaseFirestore.instance
                    .collection('services')
                    .doc(serviceId)
                    .get();

                final data = doc.data() ?? const <String, dynamic>{};
                final dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 30;

                // ✅ Aplicar SIEMPRE el procedimiento (nunca se desmarca)
                setState(() {
                  _selectedServiceId = serviceId;
                  _selectedServiceData = data;
                  _selectedDurationMin = dur;
                });

                // 🔎 Rangos incompatibles -> se borran (con confirmación SOLO OK)
                final badIdx = <int>[];
                for (int i = 0; i < _selectedRanges.length; i++) {
                  if (!_rangeFitsDuration(_selectedRanges[i], dur)) badIdx.add(i);
                }
                if (badIdx.isEmpty || !mounted) return;

                await showDialog<void>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text("Rangos demasiado pequeños"),
                    content: Text(
                      "Este procedimiento necesita ${dur} min.\n\n"
                      "Se eliminarán ${badIdx.length} rango(s) que no tienen suficiente tiempo.",
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dctx),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );

                setState(() {
                  for (final i in badIdx.reversed) {
                    _selectedRanges.removeAt(i);
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Se eliminaron rangos incompatibles (mínimo ${dur} min).")),
                );
              },

              selectedDays: _selectedDayKeys,
              selectedRanges: _selectedRanges,
              onAddDay: _addDay,
              onRemoveDayKey: _removeDayKey,
              onAddRange: _addRange,
              onRemoveRangeAt: _removeRangeAt,

              onCreate: _createRequest,
              purple: kPurple,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _activeRequestsSection(docs: activeRequestDocs, appointmentsDocs: appointmentsDocs),
      ],
    );
  }

  Widget _statsBody(Map<String, dynamic> client) {
    final stats = (client['stats'] as Map?) ?? {};
    final totalAppointments = (stats['totalAppointments'] as num?)?.toInt() ?? 0;
    final totalScheduled = (stats['totalScheduled'] as num?)?.toInt() ?? 0;
    final totalCancelled = (stats['totalCancelled'] as num?)?.toInt() ?? 0;
    final totalNoShow = (stats['totalNoShow'] as num?)?.toInt() ?? 0;

    final lastAt = stats['lastAppointmentAt'];
    final lastSummary = (stats['lastAppointmentSummary'] ?? '').toString();

    String fmtTs(dynamic v) {
      if (v is Timestamp) {
        final d = v.toDate();
        return "${_fmtDdMmYyyy(d)} • ${_fmtHm(d)}";
      }
      return "—";
    }

    final tint = _modeTint(widget.mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: _openInClientsButton())]),
        const SizedBox(height: 12),
        AppSectionCard(
          title: "Stats",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppPill(
                    background: Colors.black.withOpacity(0.06),
                    borderColor: Colors.black.withOpacity(0.12),
                    child: Text("Requested: $totalAppointments",
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  AppPill(
                    background: kPurple.withOpacity(0.10),
                    borderColor: kPurple.withOpacity(0.22),
                    child: Text("Attended: $totalScheduled",
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  AppPill(
                    background: Colors.orange.withOpacity(0.12),
                    borderColor: Colors.orange.withOpacity(0.25),
                    child: Text("Cancelled: $totalCancelled",
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  AppPill(
                    background: Colors.redAccent.withOpacity(0.12),
                    borderColor: Colors.redAccent.withOpacity(0.25),
                    child: Text("No-show: $totalNoShow",
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Last attended appointment",
                  style: TextStyle(fontWeight: FontWeight.w900, color: tint)),
              const SizedBox(height: 6),
              Text((lastSummary.isEmpty ? "—" : lastSummary),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text("Date: ${fmtTs(lastAt)}", style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientStream = FirebaseFirestore.instance.collection('clients').doc(widget.clientId).snapshots();

    final bool wantsRequests = widget.mode == HomeAdminMode.looking;
    final requestsStream = wantsRequests ? brRepo.streamActiveRequestsForClient(widget.clientId) : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: clientStream,
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final name = _fullName(data, widget.clientId);
        final contact = _contactLine(data);
        final tint = _modeTint(widget.mode);

        return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: requestsStream,
          builder: (context, reqSnap) {
            final activeDocs =
                wantsRequests ? (reqSnap.data ?? const []) : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final screenH = MediaQuery.of(context).size.height;

            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            final allowOuterScroll = _creatingRequest || keyboardOpen || screenH < 640;

            final targetH =
                (keyboardOpen ? screenH * 0.90 : screenH * 0.82).clamp(screenH * 0.42, screenH * 0.90);

            return SafeArea(
              top: false,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: targetH,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 6,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppPill(
                          background: tint.withOpacity(0.10),
                          borderColor: tint.withOpacity(0.22),
                          child: Icon(_modeIcon(widget.mode), size: 16, color: tint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppPreviewCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          if (contact.isNotEmpty) Text(contact, style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: allowOuterScroll
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: (widget.mode == HomeAdminMode.looking)
                              ? Builder(
                                  builder: (_) {
                                    DateTime? minDay;
                                    DateTime? maxDay;

                                    for (final d in activeDocs) {
                                      final br = d.data();
                                      final days = (br['preferredDays'] as List?)?.map((e) => e.toString()).toList() ??
                                          const <String>[];
                                      for (final dayKey in days) {
                                        final dt = BookingRequestUtils.parseYyyymmdd(dayKey);
                                        if (dt == null) continue;
                                        minDay = (minDay == null || dt.isBefore(minDay)) ? dt : minDay;
                                        maxDay = (maxDay == null || dt.isAfter(maxDay)) ? dt : maxDay;
                                      }
                                    }

                                    if (minDay == null || maxDay == null) {
                                      return _lookingBody(
                                        client: data,
                                        activeRequestDocs: activeDocs,
                                        appointmentsDocs: const [],
                                      );
                                    }

                                    final q = FirebaseFirestore.instance
                                        .collection('appointments')
                                        .where('appointmentDate',
                                            isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(minDay)))
                                        .where('appointmentDate',
                                            isLessThan: Timestamp.fromDate(_endExclusive(maxDay)));

                                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      stream: q.snapshots(),
                                      builder: (context, apptSnap) {
                                        final apptDocs = apptSnap.data?.docs ??
                                            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                                        return _lookingBody(
                                          client: data,
                                          activeRequestDocs: activeDocs,
                                          appointmentsDocs: apptDocs,
                                        );
                                      },
                                    );
                                  },
                                )
                              : _statsBody(data),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}