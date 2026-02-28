import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  DateTime? preferredDay;
  TimeOfDay? rangeStart;
  TimeOfDay? rangeEnd;

  String? _selectedWorkerId; // null => any worker
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedServiceData;
  int _selectedDurationMin = 30;

  static const Color kPurple = Color(0xff721c80);

  @override
  void initState() {
    super.initState();
    brRepo = BookingRequestRepo(FirebaseFirestore.instance);

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

  String _fmtDdMm(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

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

  DateTime? _firstSlotOnDayForWorker({
    required DateTime day,
    required List<Map<String, int>> ranges,
    required int durMin,
    required String workerId,
    required int allowedOverlap,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    for (final r in ranges) {
      final rs = r['startMin'] ?? 0;
      final re = r['endMin'] ?? (24 * 60);

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

  ({BookingRequestAvailability status, DateTime? nextStart}) _availabilityInfoForRequest({
    required Map<String, dynamic> br,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    final workerId = (br['workerId'] ?? '').toString().trim();
    final isAnyWorker = workerId.isEmpty;

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

    // worker Any: por ahora checking (lo hacemos exacto cuando metas workers list)
    if (isAnyWorker) {
      return (status: BookingRequestAvailability.unknown, nextStart: null);
    }

    // exact slots
    for (final x in exactSlots) {
      if (x is! Timestamp) continue;
      final dt = x.toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      final sMin = dt.hour * 60 + dt.minute;

      final ok = _slotOkForWorkerWithTolerance(
        day: day,
        startMin: sMin,
        durMin: durMin,
        workerId: workerId,
        allowedOverlap: allowedOverlap,
        appts: appts,
      );
      if (ok) return (status: BookingRequestAvailability.available, nextStart: dt);
    }

    // preferred days
    final parsedDays = preferredDays
        .map((k) => BookingRequestUtils.parseYyyymmdd(k))
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    for (final day in parsedDays) {
      final first = _firstSlotOnDayForWorker(
        day: day,
        ranges: ranges,
        durMin: durMin,
        workerId: workerId,
        allowedOverlap: allowedOverlap,
        appts: appts,
      );
      if (first != null) {
        return (status: BookingRequestAvailability.available, nextStart: first);
      }
    }

    return (status: BookingRequestAvailability.unavailable, nextStart: null);
  }

  String _pillLabelForRequest(BookingRequestAvailability status, DateTime? nextStart) {
    if (status == BookingRequestAvailability.unknown) return "Checking…";
    if (status == BookingRequestAvailability.unavailable) return "No availability";
    if (nextStart == null) return " ";

    final hm =
        "${nextStart.hour.toString().padLeft(2, '0')}:${nextStart.minute.toString().padLeft(2, '0')}";
    final ddmm = _fmtDdMm(nextStart);
    return "$hm - $ddmm";
  }

  // ===================== Create request =====================

  Future<void> _createRequest() async {
    if (_selectedServiceId == null || _selectedServiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a procedure first")),
      );
      return;
    }

    final preferredDays = <String>[];
    if (preferredDay != null) preferredDays.add(BookingRequestUtils.yyyymmdd(preferredDay!));

    final ranges = <Map<String, int>>[];
    if (rangeStart != null && rangeEnd != null) {
      ranges.add(BookingRequestUtils.range(rangeStart!, rangeEnd!));
    }

    if (_selectedServiceData == null) {
      final doc = await FirebaseFirestore.instance.collection('services').doc(_selectedServiceId!).get();
      _selectedServiceData = doc.data();
    }

    final svc = _selectedServiceData ?? const <String, dynamic>{};
    final nameKey = (svc['name'] ?? '').toString();
    final label = nameKey.isNotEmpty ? nameKey : _selectedServiceId!;
    final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : _selectedDurationMin;

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
      preferredDay = null;
      rangeStart = null;
      rangeEnd = null;
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

    DateTime? day;
    final days = (br['preferredDays'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    if (days.isNotEmpty) day = BookingRequestUtils.parseYyyymmdd(days.first);

    TimeOfDay? start;
    TimeOfDay? end;
    final ranges = (br['preferredTimeRanges'] as List?) ?? const [];
    if (ranges.isNotEmpty && ranges.first is Map) {
      final m = Map<String, dynamic>.from(ranges.first as Map);
      final s = (m['startMin'] ?? m['start']);
      final e = (m['endMin'] ?? m['end']);
      final sm = (s is num) ? s.toInt() : int.tryParse('$s') ?? -1;
      final em = (e is num) ? e.toInt() : int.tryParse('$e') ?? -1;
      if (sm >= 0 && em > sm) {
        start = TimeOfDay(hour: sm ~/ 60, minute: sm % 60);
        end = TimeOfDay(hour: em ~/ 60, minute: em % 60);
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
                final svcDoc =
                    await FirebaseFirestore.instance.collection('services').doc(serviceId!).get();
                final svc = svcDoc.data() ?? const <String, dynamic>{};

                final nameKey = (svc['name'] ?? '').toString();
                final label = nameKey.isNotEmpty ? nameKey : serviceId!;
                final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : 30;

                final preferredDays = <String>[];
                if (day != null) preferredDays.add(BookingRequestUtils.yyyymmdd(day!));

                final preferredRanges = <Map<String, int>>[];
                if (start != null && end != null) {
                  preferredRanges.add(BookingRequestUtils.range(start!, end!));
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
                    onServiceChanged: (v) => setLocal(() => serviceId = v),

                    preferredDay: day,
                    rangeStart: start,
                    rangeEnd: end,
                    onDayChanged: (d) => setLocal(() => day = d),
                    onStartChanged: (t) => setLocal(() => start = t),
                    onEndChanged: (t) => setLocal(() => end = t),

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

                final doc = await FirebaseFirestore.instance.collection('services').doc(serviceId).get();
                final data = doc.data() ?? const <String, dynamic>{};
                final dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 30;

                setState(() {
                  _selectedServiceId = serviceId;
                  _selectedServiceData = data;
                  _selectedDurationMin = dur;
                });
              },

              preferredDay: preferredDay,
              rangeStart: rangeStart,
              rangeEnd: rangeEnd,
              onDayChanged: (d) => setState(() => preferredDay = d),
              onStartChanged: (t) => setState(() => rangeStart = t),
              onEndChanged: (t) => setState(() => rangeEnd = t),

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
        final dd = d.day.toString().padLeft(2, '0');
        final mm = d.month.toString().padLeft(2, '0');
        final yy = d.year.toString();
        final hh = d.hour.toString().padLeft(2, '0');
        final mi = d.minute.toString().padLeft(2, '0');
        return "$dd/$mm/$yy • $hh:$mi";
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
            final activeDocs = wantsRequests ? (reqSnap.data ?? const []) : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
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
                        physics: allowOuterScroll ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: (widget.mode == HomeAdminMode.looking)
                              ? Builder(
                                  builder: (_) {
                                    DateTime? minDay;
                                    DateTime? maxDay;

                                    for (final d in activeDocs) {
                                      final br = d.data();
                                      final days = (br['preferredDays'] as List?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
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
                                        .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(minDay)))
                                        .where('appointmentDate', isLessThan: Timestamp.fromDate(_endExclusive(maxDay)));

                                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      stream: q.snapshots(),
                                      builder: (context, apptSnap) {
                                        final apptDocs = apptSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
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