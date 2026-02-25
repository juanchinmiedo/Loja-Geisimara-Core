import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/components/ui/app_preview_card.dart';
import 'package:salon_app/components/ui/app_pill.dart';
import 'package:salon_app/components/ui/app_icon_pill_button.dart';
import 'package:salon_app/components/ui/app_icon_value_pill_button.dart';

import 'package:salon_app/widgets/async_optimistic_switch.dart';
import 'package:salon_app/widgets/worker_choice_pills.dart';
import 'package:salon_app/widgets/booking_request_pickers_pills.dart';

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

  final notesCtrl = TextEditingController();
  DateTime? preferredDay;
  TimeOfDay? rangeStart;
  TimeOfDay? rangeEnd;

  String? _selectedWorkerId; // null => any worker

  static const Color kPurple = Color(0xff721c80);

  @override
  void initState() {
    super.initState();
    brRepo = BookingRequestRepo(FirebaseFirestore.instance);

    // ✅ limpieza automática al abrir (expiradas)
    brRepo.pruneExpiredActiveRequests(clientId: widget.clientId);
  }

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
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

  String _formatRange(Map<String, dynamic> r) {
    final s = (r['startMin'] as num?)?.toInt() ?? 0;
    final e = (r['endMin'] as num?)?.toInt() ?? 0;
    String hm(int m) =>
        "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";
    return "${hm(s)} - ${hm(e)}";
  }

  Future<void> _createRequest() async {
    final preferredDays = <String>[];
    if (preferredDay != null) {
      preferredDays.add(BookingRequestUtils.yyyymmdd(preferredDay!));
    }

    final ranges = <Map<String, int>>[];
    if (rangeStart != null && rangeEnd != null) {
      ranges.add(BookingRequestUtils.range(rangeStart!, rangeEnd!));
    }

    await brRepo.upsertRequest(
      clientId: widget.clientId,
      workerId: _selectedWorkerId, // ✅
      exactSlots: const [],
      preferredDays: preferredDays,
      preferredTimeRanges: ranges,
      notes: notesCtrl.text.trim(),
    );

    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
      "bookingRequestActive": true,
      "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _creatingRequest = false;
      notesCtrl.clear();
      preferredDay = null;
      rangeStart = null;
      rangeEnd = null;
      _selectedWorkerId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking request created")),
    );
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

  // ─────────────────────────────
  // HEIGHT RULES (0/1/2 visible; >2 scroll inside list)
  // ─────────────────────────────
  double _sheetHeight({
    required double screenH,
    required int requestCount,
    required bool allowOuterScroll,
  }) {
    const base = 468.0;
    const perItem = 118.0;

    final visible = requestCount <= 0 ? 0 : (requestCount == 1 ? 1 : 2);
    final raw = base + (visible * perItem);

    final minH = allowOuterScroll ? screenH * 0.35 : screenH * 0.42;
    final maxH = screenH * 0.82;

    return raw.clamp(minH, maxH);
  }

  double _activeListHeightForCount(int count) {
    const perItem = 118.0;
    const paddingAir = 6.0;
    final visible = count <= 0 ? 0 : (count == 1 ? 1 : 2);
    return (visible * perItem) + paddingAir;
  }

  Widget _requestTile({
    required String requestId,
    required Map<String, dynamic> br,
  }) {
    final days = (br['preferredDays'] as List?) ?? const [];
    final ranges = (br['preferredTimeRanges'] as List?) ?? const [];
    final notes = (br['notes'] ?? '').toString();
    final wid = br['workerId'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Request", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text("• Worker: ${wid == null ? 'Any' : wid}"),
                if (days.isNotEmpty)
                  Text(
                    "• Day(s): ${days.map((d) => BookingRequestUtils.formatYyyyMmDdToDdMmYyyy(d.toString())).join(', ')}",
                  ),
                if (ranges.isNotEmpty)
                  Text(
                    "• Range(s): ${ranges.map((r) {
                      final m = Map<String, dynamic>.from(r as Map);
                      return _formatRange(m);
                    }).join('; ')}",
                  ),
                if (notes.isNotEmpty) Text("• Notes: $notes"),
                const SizedBox(height: 18),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: AppIconPillButton(
              icon: Icons.delete_outline,
              color: Colors.redAccent,
              shadow: false,
              tooltip: "Delete request",
              onTap: () async {
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
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: AppIconPillButton(
              icon: Icons.edit_outlined,
              color: kPurple,
              shadow: false,
              tooltip: "Edit notes",
              onTap: () async {
                final editNotes = TextEditingController(text: notes);

                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Edit request"),
                    content: TextField(
                      controller: editNotes,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Notes",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kPurple),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (ok == true) {
                  await brRepo.updateRequestNotes(
                    requestId: requestId,
                    notes: editNotes.text.trim(),
                  );
                }

                editNotes.dispose();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRequestsSection({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (docs.isEmpty) {
      return AppSectionCard(
        title: "Active booking requests",
        child: Text("No active booking requests yet.", style: TextStyle(color: Colors.grey[700])),
      );
    }

    final count = docs.length;
    final panelH = _activeListHeightForCount(count);
    final mustScrollInside = count > 2;

    return AppSectionCard(
      title: "Active booking requests",
      child: SizedBox(
        height: panelH,
        child: mustScrollInside
            ? ListView.separated(
                key: PageStorageKey("home_active_requests_${widget.clientId}"),
                padding: const EdgeInsets.only(top: 3, bottom: 3),
                physics: const ClampingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i];
                  return _requestTile(
                    requestId: d.id,
                    br: d.data(),
                  );
                },
              )
            : Column(
                children: [
                  for (int i = 0; i < docs.length && i < 2; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _requestTile(
                      requestId: docs[i].id,
                      br: docs[i].data(),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _lookingBody({
    required Map<String, dynamic> client,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> activeRequestDocs,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: notesCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Notes / preferences",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Worker pills (Any / worker específico)
                const Text("Worker", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                WorkerChoicePills(
                  value: _selectedWorkerId,
                  onChanged: (v) => setState(() => _selectedWorkerId = v),
                  anyLabel: "Any",
                ),

                const SizedBox(height: 12),

                // ✅ Pickers pills (día/start/end)
                BookingRequestPickersPills(
                  preferredDay: preferredDay,
                  rangeStart: rangeStart,
                  rangeEnd: rangeEnd,
                  onDayChanged: (d) => setState(() => preferredDay = d),
                  onStartChanged: (t) => setState(() => rangeStart = t),
                  onEndChanged: (t) => setState(() => rangeEnd = t),
                  purple: kPurple,
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _createRequest,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Create request",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        _activeRequestsSection(docs: activeRequestDocs),
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
    final clientStream =
        FirebaseFirestore.instance.collection('clients').doc(widget.clientId).snapshots();

    final bool wantsRequests = widget.mode == HomeAdminMode.looking;
    final requestsStream =
        wantsRequests ? brRepo.streamActiveRequestsForClient(widget.clientId) : null;

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
            final activeDocs = wantsRequests
                ? (reqSnap.data ?? const [])
                : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final requestCount = wantsRequests ? activeDocs.length : 0;

            final screenH = MediaQuery.of(context).size.height;

            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            final allowOuterScroll = _creatingRequest || keyboardOpen || screenH < 640;

            final targetH = _sheetHeight(
              screenH: screenH,
              requestCount: requestCount,
              allowOuterScroll: allowOuterScroll,
            );

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
                          if (contact.isNotEmpty)
                            Text(contact, style: TextStyle(color: Colors.grey[700])),
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
                              ? _lookingBody(client: data, activeRequestDocs: activeDocs)
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