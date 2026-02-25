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

  String _notesDraft = '';
  int _notesResetToken = 0;
  String? _selectedWorkerId; // null => Any
  DateTime? preferredDay;
  TimeOfDay? rangeStart;
  TimeOfDay? rangeEnd;

  Map<String, dynamic> _clientData = {};

  static const Color kPurple = Color(0xff721c80);

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
    final preferredDays = <String>[];
    if (preferredDay != null) {
      preferredDays.add(BookingRequestUtils.yyyymmdd(preferredDay!));
    }

    final ranges = <Map<String, int>>[];
    if (rangeStart != null && rangeEnd != null) {
      ranges.add(BookingRequestUtils.range(rangeStart!, rangeEnd!));
    }

    await brRepo.upsertRequest(
      workerId: _selectedWorkerId,
      clientId: widget.clientId,
      exactSlots: const [],
      preferredDays: preferredDays,
      preferredTimeRanges: ranges,
      notes: _notesDraft.trim(),
    );

    await FirebaseFirestore.instance.collection('clients').doc(widget.clientId).set({
      "bookingRequestActive": true,
      "bookingRequestUpdatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _looking = true;
      _openAddRequest = false;
      _notesDraft = '';
      _notesResetToken++;
      preferredDay = null;
      rangeStart = null;
      rangeEnd = null;
      _selectedWorkerId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking request created")));
  }

  Future<void> _editRequestNotesDialog(String requestId, Map<String, dynamic> data) async {
    String draft = (data['notes'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text("Edit request"),
            content: TextFormField(
              initialValue: draft,
              minLines: 1,
              maxLines: 4,
              onChanged: (v) => setLocal(() => draft = v),
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(ctx).unfocus();
                  Navigator.pop(ctx, false);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPurple),
                onPressed: () {
                  FocusScope.of(ctx).unfocus();
                  Navigator.pop(ctx, true);
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    if (ok == true) {
      await brRepo.updateRequestNotes(
        requestId: requestId,
        notes: draft.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request updated")),
        );
      }
    }
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
      onEditNotes: () => _editRequestNotesDialog(requestId, br),
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
                notesValue: _notesDraft,
                  onNotesChanged: (v) => setState(() => _notesDraft = v),
                  notesResetToken: _notesResetToken,
                  selectedWorkerId: _selectedWorkerId,
                  onWorkerChanged: (v) => setState(() => _selectedWorkerId = v),
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