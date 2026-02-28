import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_pill.dart';
import 'package:salon_app/components/ui/app_preview_card.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/client_card.dart';

import 'package:salon_app/widgets/booking_request_card.dart';
import 'package:salon_app/widgets/booking_request_create_form.dart';
import 'package:salon_app/widgets/async_optimistic_switch.dart';

import 'package:salon_app/repositories/booking_request_repo.dart';

import 'package:salon_app/utils/booking_request_utils.dart';

import 'package:salon_app/services/client_service.dart';

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

  late final ClientService _clientService;

  @override
  void initState() {
    super.initState();
    _clientService = ClientService(FirebaseFirestore.instance);
  }

  Future<void> _openCreateClientDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateClientDialog(clientService: _clientService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final nav = context.watch<AdminNavProvider>();

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
        .limit(400)
        .snapshots();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppGradientHeader(
              title: "Clients",
              subtitle: "Search by name/phone/instagram",
              child: LayoutBuilder(
                builder: (context, c) {
                  const btnSize = 44.0;
                  const gap = 10.0;

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                            prefixIcon: const Icon(Icons.search),
                            hintText: "Search by tokens (name/phone/instagram)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        height: btnSize,
                        width: btnSize,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openCreateClientDialog,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withOpacity(0.35)),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Color(0xff721c80),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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

                  filtered.sort((a, b) {
                    final av = a.data()['bookingRequestActive'] == true ? 1 : 0;
                    final bv = b.data()['bookingRequestActive'] == true ? 1 : 0;
                    return bv.compareTo(av);
                  });

                  return Column(
                    children: filtered.map((d) {
                      final data = d.data();
                      final hasReq = data['bookingRequestActive'] == true;

                      return ClientCard(
                        data: data,
                        showChevron: true,
                        trailingBeforeChevron: hasReq
                            ? AppPill(
                                background: const Color(0xff721c80).withOpacity(0.10),
                                borderColor: const Color(0xff721c80).withOpacity(0.25),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16,
                                  color: Color(0xff721c80),
                                ),
                              )
                            : null,
                        onTap: () => _openClientBottomSheet(context, d.id),
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

  Future<void> _openClientBottomSheet(BuildContext context, String clientId) async {
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ClientBottomSheet(clientId: clientId),
    );
  }
}

enum _PanelOpen { booking, edit }

class _ClientBottomSheet extends StatefulWidget {
  const _ClientBottomSheet({required this.clientId});
  final String clientId;

  @override
  State<_ClientBottomSheet> createState() => _ClientBottomSheetState();
}

class _ClientBottomSheetState extends State<_ClientBottomSheet> {
  late final BookingRequestRepo brRepo;

  final fnCtrl = TextEditingController();
  final lnCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final igCtrl = TextEditingController();

  bool _loading = true;
  bool _looking = false;

  _PanelOpen? _openPanel;
  bool _openAddRequest = false;

  String? _selectedWorkerId; // null => Any
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedServiceData;
  // NEW: multi-day + multi-range
  final List<String> _selectedDayKeys = <String>[]; // yyyymmdd
  final List<Map<String, int>> _selectedRanges = <Map<String, int>>[]; // {startMin,endMin}

  Map<String, dynamic> _clientData = {};

  static const Color kPurple = Color(0xff721c80);

  // límites
  static const int _startMinClamp = 7 * 60 + 30;
  static const int _startMaxClamp = 19 * 60;
  static const int _endMinClamp = 9 * 60;
  static const int _endMaxClamp = 21 * 60;

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
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return;
    final fixedStart = _clampTime(start, _startMinClamp, _startMaxClamp);

    final minAllowed = (_toMin(fixedStart) < _endMinClamp) ? _endMinClamp : _toMin(fixedStart);
    final end = await showTimePicker(
      context: context,
      initialTime: _fromMin(minAllowed),
    );
    if (end == null) return;
    var fixedEnd = _clampTime(end, _endMinClamp, _endMaxClamp);
    if (_toMin(fixedEnd) < _toMin(fixedStart)) {
      fixedEnd = _clampTime(fixedStart, _endMinClamp, _endMaxClamp);
    }

    setState(() {
      _selectedRanges.add(BookingRequestUtils.range(fixedStart, fixedEnd));
    });
  }

  void _removeRangeAt(int i) {
    if (i < 0 || i >= _selectedRanges.length) return;
    setState(() => _selectedRanges.removeAt(i));
  }

  @override
  void initState() {
    super.initState();
    brRepo = BookingRequestRepo(FirebaseFirestore.instance);
    _loadClient();

    // si tienes prune en repo:
    // brRepo.pruneExpiredActiveRequests(clientId: widget.clientId);
  }

  Future<void> _loadClient() async {
    final snap = await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).get();
    _clientData = snap.data() ?? {};

    fnCtrl.text = (_clientData['firstName'] ?? '').toString();
    lnCtrl.text = (_clientData['lastName'] ?? '').toString();
    countryCtrl.text = (_clientData['country'] ?? '').toString();
    phoneCtrl.text = (_clientData['phone'] ?? '').toString();
    igCtrl.text = (_clientData['instagram'] ?? '').toString();

    _looking = _clientData['bookingRequestActive'] == true;

    if (mounted) setState(() => _loading = false);
  }

  String _fullName(Map<String, dynamic> data, String fallback) {
    final fn = (data['firstName'] ?? '').toString().trim();
    final ln = (data['lastName'] ?? '').toString().trim();
    final name = ('$fn $ln').trim();
    return name.isEmpty ? fallback : name;
  }

  String _contactLine(Map<String, dynamic> data) {
    final ctry = (data['country'] is num)
        ? (data['country'] as num).toInt()
        : int.tryParse('${data['country'] ?? ''}') ?? 0;
    final ph = (data['phone'] is num)
        ? (data['phone'] as num).toInt()
        : int.tryParse('${data['phone'] ?? ''}') ?? 0;
    final ig = (data['instagram'] ?? '').toString().trim();

    final parts = <String>[];
    if (ctry > 0 && ph > 0) parts.add('+$ctry $ph');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  @override
  void dispose() {
    fnCtrl.dispose();
    lnCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    igCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveClientEdits() async {
    final ctry = int.tryParse(countryCtrl.text.trim()) ?? 0;
    final ph = int.tryParse(phoneCtrl.text.trim()) ?? 0;

    final ref = FirebaseFirestore.instance.collection('clients').doc(widget.clientId);
    await ref.set({
      'firstName': fnCtrl.text.trim(),
      'lastName': lnCtrl.text.trim(),
      'country': ctry,
      'phone': ph,
      'instagram': igCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteClient() async {
    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).delete();
  }

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
              : "This will delete ALL active booking requests for this client (${docs.length}) and disable the switch. Continue?",
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
    setState(() {
      _looking = false;
      _openPanel = null;
      _openAddRequest = false;
    });
  }

  Future<void> _createRequest() async {
    if (_selectedServiceId == null || _selectedServiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a procedure first")),
      );
      return;
    }

    final preferredDays = List<String>.from(_selectedDayKeys);
    final ranges = List<Map<String, int>>.from(_selectedRanges);

    // ✅ load service data (durationMin)
    if (_selectedServiceData == null) {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(_selectedServiceId!)
          .get();
      _selectedServiceData = doc.data();
    }

    final svc = _selectedServiceData ?? const <String, dynamic>{};
    final nameKey = (svc['name'] ?? '').toString();
    final label = nameKey.isNotEmpty ? nameKey : _selectedServiceId!;
    final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : 30;

    // ✅ NEW: si ya existe un appointment FUTURO de la misma category, pedir confirmación
    final selectedCategory = (svc['category'] ?? 'hands').toString();
    try {
      final now = Timestamp.now();
      final apptsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('clientId', isEqualTo: widget.clientId)
          .where('status', isEqualTo: 'scheduled')
          .where('appointmentDate', isGreaterThanOrEqualTo: now)
          .limit(20)
          .get();

      bool hasSameCategory = false;
      final cache = <String, String>{};
      for (final a in apptsSnap.docs) {
        final sid = (a.data()['serviceId'] ?? '').toString();
        if (sid.isEmpty) continue;
        final cat = cache[sid] ??
            ((await FirebaseFirestore.instance.collection('services').doc(sid).get()).data()?['category'] ?? 'hands')
                .toString();
        cache[sid] = cat;
        if (cat == selectedCategory) {
          hasSameCategory = true;
          break;
        }
      }

      if (hasSameCategory) {
        final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Appointment already exists'),
                  content: Text(
                    "This client already has a scheduled appointment for category '$selectedCategory'. Create a booking request anyway?",
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

    await brRepo.upsertRequest(
      workerId: _selectedWorkerId,
      clientId: widget.clientId,

      // ✅ procedure fields
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
      _looking = true;
      _openAddRequest = false;
      _selectedDayKeys.clear();
      _selectedRanges.clear();
      _selectedWorkerId = null;

      _selectedServiceId = null;
      _selectedServiceData = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking request created")),
    );
  }

  Future<void> _editRequestSheet({
    required String requestId,
    required Map<String, dynamic> br,
  }) async {
    // Prefill
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
                // Load service info (duration + name)
                final svcDoc = await FirebaseFirestore.instance.collection('services').doc(serviceId!).get();
                final svc = svcDoc.data() ?? const <String, dynamic>{};

                final nameKey = (svc['name'] ?? '').toString();
                final label = nameKey.isNotEmpty ? nameKey : serviceId!;
                final dur = (svc['durationMin'] is num) ? (svc['durationMin'] as num).toInt() : 30;

                final preferredDays = List<String>.from(dayKeys);
                final preferredRanges = List<Map<String, int>>.from(rangeList);

                await brRepo.updateRequest(
                  requestId: requestId,
                  workerId: workerId, // null => Any
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
                        child: Text("Edit request", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                      IconButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  BookingRequestCreateForm(
                    selectedWorkerId: workerId,
                    onWorkerChanged: (v) => setLocal(() => workerId = v),

                    selectedServiceId: serviceId,
                    onServiceChanged: (v) => setLocal(() => serviceId = v),

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
                      final start = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (start == null) return;
                      final sMin = start.hour * 60 + start.minute;
                      final end = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(hour: (sMin ~/ 60).clamp(0, 23), minute: (sMin % 60).clamp(0, 59)),
                      );
                      if (end == null) return;
                      final eMin = end.hour * 60 + end.minute;
                      if (eMin <= sMin) return;
                      setLocal(() => rangeList.add({'startMin': sMin, 'endMin': eMin}));
                    },
                    onRemoveRangeAt: (i) {
                      if (i < 0 || i >= rangeList.length) return;
                      setLocal(() => rangeList.removeAt(i));
                    },

                    onCreate: save,
                    purple: kPurple,
                  ),

                  const SizedBox(height: 10),
                  if (saving)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _panelHeader({required String title, required bool open, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            Icon(open ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  // ✅ misma card compacta que Home (edit y delete en pills)
  Widget _requestCard({
    required String requestId,
    required Map<String, dynamic> br,
  }) {
    return BookingRequestCard(
      requestId: requestId,
      br: br,
      purple: kPurple,
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
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 24, top: 24),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _fullName(_clientData, s.clientFallback);
    final contact = _contactLine(_clientData);

    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 16 + bottomInset),
      child: SingleChildScrollView(
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
                if (_looking)
                  AppPill(
                    background: kPurple.withOpacity(0.10),
                    borderColor: kPurple.withOpacity(0.25),
                    child: const Icon(Icons.notifications_active_outlined, size: 16, color: kPurple),
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
                  Text(contact, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: "Booking request",
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _looking ? "Looking for appointment" : "Not looking",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  AsyncOptimisticSwitch(
                    value: _looking,
                    switchActiveColor: kPurple,
                    onSave: (v) async {
                      if (!v) {
                        await _confirmAndDisableLooking();
                        return;
                      }
                      setState(() => _looking = true);
                      await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
                        "bookingRequestActive": true,
                        "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_looking) ...[
              _buildPanelBookingRequests(),
              const SizedBox(height: 14),
            ],
            _buildPanelEditClient(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
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

                  await _deleteClient();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client deleted")));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text("Delete client"),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  context.read<AdminNavProvider>().goToBookingWithClient(widget.clientId);
                  Navigator.pop(context);
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
      ),
    );
  }

  Widget _buildPanelBookingRequests() {
    final open = _openPanel == _PanelOpen.booking;

    return Column(
      children: [
        _panelHeader(
          title: "Booking requests",
          open: open,
          onTap: () {
            setState(() {
              _openPanel = open ? null : _PanelOpen.booking;
              if (_openPanel != _PanelOpen.booking) _openAddRequest = false;
            });
          },
        ),
        if (open) ...[
          const SizedBox(height: 10),

          StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: brRepo.streamActiveRequestsForClient(widget.clientId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return Text("No active booking requests yet.", style: TextStyle(color: Colors.grey[700]));
              }

              return Column(
                children: docs.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _requestCard(requestId: d.id, br: d.data()),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 10),

          _panelHeader(
            title: "Add booking request",
            open: _openAddRequest,
            onTap: () => setState(() => _openAddRequest = !_openAddRequest),
          ),

          if (_openAddRequest) ...[
            const SizedBox(height: 10),
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
                    });
                    return;
                  }

                  final doc = await FirebaseFirestore.instance.collection('services').doc(serviceId).get();
                  setState(() {
                    _selectedServiceId = serviceId;
                    _selectedServiceData = doc.data();
                  });
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
        ],
      ],
    );
  }

  Widget _buildPanelEditClient() {
    final open = _openPanel == _PanelOpen.edit;

    return Column(
      children: [
        _panelHeader(
          title: "Edit client",
          open: open,
          onTap: () {
            setState(() {
              _openPanel = open ? null : _PanelOpen.edit;
              if (_openPanel == _PanelOpen.edit) _openAddRequest = false;
            });
          },
        ),
        if (open) ...[
          const SizedBox(height: 10),
          AppSectionCard(
            title: "Client data",
            child: Column(
              children: [
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
                        decoration: const InputDecoration(labelText: "Country", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          title: const Text("Confirm edit"),
                          content: const Text("Save changes to this client?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text("No")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: kPurple),
                              onPressed: () => Navigator.pop(dctx, true),
                              child: const Text("Yes", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;

                      await _saveClientEdits();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client updated")));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text("Save client"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CreateClientDialog extends StatefulWidget {
  const _CreateClientDialog({required this.clientService});
  final ClientService clientService;

  @override
  State<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<_CreateClientDialog> {
  final formKey = GlobalKey<FormState>();

  final fnCtrl = TextEditingController();
  final lnCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final igCtrl = TextEditingController();

  bool saving = false;

  int _i(String s) => int.tryParse(s.trim()) ?? 0;

  @override
  void dispose() {
    fnCtrl.dispose();
    lnCtrl.dispose();
    countryCtrl.dispose();
    phoneCtrl.dispose();
    igCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Expanded(
            child: Text("Create client", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          IconButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: fnCtrl,
                decoration: const InputDecoration(labelText: "First name", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: lnCtrl,
                decoration: const InputDecoration(labelText: "Last name", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: countryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Country", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Phone", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: igCtrl,
                decoration: const InputDecoration(labelText: "Instagram (optional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Text(
                "Phone OR Instagram required",
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff721c80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: saving
                ? null
                : () async {
                    final ok = formKey.currentState?.validate() == true;
                    if (!ok) return;

                    final ctry = _i(countryCtrl.text);
                    final ph = _i(phoneCtrl.text);
                    final ig = widget.clientService.normalizeInstagram(igCtrl.text);

                    final hasPhone = ctry > 0 && ph > 0;
                    if (!hasPhone && ig.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Phone or Instagram required")),
                      );
                      return;
                    }

                    setState(() => saving = true);
                    try {
                      await widget.clientService.createOrGetClient(
                        context: context,
                        firstName: fnCtrl.text.trim(),
                        lastName: lnCtrl.text.trim(),
                        country: ctry,
                        phone: ph,
                        instagramRaw: igCtrl.text,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Client created")),
                      );
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}