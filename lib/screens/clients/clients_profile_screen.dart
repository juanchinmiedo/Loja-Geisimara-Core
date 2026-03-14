// lib/screens/clients/client_profile_screen.dart
//
// Pantalla de perfil completo de cliente.
// Reemplaza el bottom-sheet anterior con una pantalla completa que añade
// historial de citas en tabs (Upcoming / Past).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_section_card.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/repositories/booking_request_repo.dart';
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

  late final TabController _tabController;
  late final BookingRequestRepo _brRepo;

  Map<String, dynamic> _clientData = {};
  bool _loading = true;
  bool _looking = false;

  // Edit controllers
  final _fnCtrl      = TextEditingController();
  final _lnCtrl      = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _igCtrl      = TextEditingController();

  // Booking request creation
  String? _selectedWorkerId;
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedServiceData;
  final List<String> _selectedDayKeys = [];
  final List<Map<String, int>> _selectedRanges = [];
  bool _showAddRequest = false;

  // Panel state (edit)
  bool _editOpen = false;

  static const int _startMinClamp = 7 * 60 + 30;
  static const int _startMaxClamp = 19 * 60;
  static const int _endMinClamp   = 9 * 60;
  static const int _endMaxClamp   = 21 * 60;

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
    _fnCtrl.dispose();
    _lnCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _igCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadClient() async {
    final snap = await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId)
        .get();
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
    final fn = (_clientData['firstName'] ?? '').toString().trim();
    final ln = (_clientData['lastName']  ?? '').toString().trim();
    final v = '$fn $ln'.trim();
    return v.isEmpty ? S.of(context).clientFallback : v;
  }

  String _contactLine() {
    final c = _num('country');
    final p = _num('phone');
    final ig = (_clientData['instagram'] ?? '').toString().trim();
    final parts = <String>[];
    if (c > 0 && p > 0) parts.add('+$c $p');
    if (ig.isNotEmpty) parts.add('@$ig');
    return parts.join(' • ');
  }

  int _num(String key) {
    final v = _clientData[key];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _saveClientEdits() async {
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId)
        .set({
      'firstName': _fnCtrl.text.trim(),
      'lastName':  _lnCtrl.text.trim(),
      'country':   int.tryParse(_countryCtrl.text.trim()) ?? 0,
      'phone':     int.tryParse(_phoneCtrl.text.trim()) ?? 0,
      'instagram': _igCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteClient() async {
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId)
        .delete();
  }

  // ── Booking request actions ──────────────────────────────────────────────────

  Future<void> _addDay() async {
    final now   = DateTime.now();
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

  Future<void> _addRange() async {
    final start = await AppTimePicker.pick5m(
        context: context, initial: const TimeOfDay(hour: 9, minute: 0));
    if (start == null) return;
    final fixedStart = TimeOfDayUtils.clamp(
        start, minMinutes: _startMinClamp, maxMinutes: _startMaxClamp);
    final minAllowed = TimeOfDayUtils.toMinutes(fixedStart) < _endMinClamp
        ? _endMinClamp
        : TimeOfDayUtils.toMinutes(fixedStart);
    final end = await AppTimePicker.pick5m(
        context: context,
        initial: TimeOfDayUtils.fromMinutes(minAllowed));
    if (end == null) return;
    var fixedEnd = TimeOfDayUtils.clamp(
        end, minMinutes: _endMinClamp, maxMinutes: _endMaxClamp);
    if (TimeOfDayUtils.isBefore(fixedEnd, fixedStart)) {
      fixedEnd = TimeOfDayUtils.clamp(
          fixedStart, minMinutes: _endMinClamp, maxMinutes: _endMaxClamp);
    }
    setState(() =>
        _selectedRanges.add(BookingRequestUtils.range(fixedStart, fixedEnd)));
  }

  Future<void> _confirmAndDisableLooking() async {
    final docs = await _brRepo.getActiveRequestsForClient(widget.clientId);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable booking requests?'),
        content: Text(docs.isEmpty
            ? "This will disable 'Looking for appointment'. Continue?"
            : 'This will delete ALL active booking requests (${docs.length}) and disable the switch. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (docs.isNotEmpty) await _brRepo.deleteAllActiveForClient(widget.clientId);
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId)
        .set({
      'bookingRequestActive': false,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {
      _looking = false;
      _showAddRequest = false;
    });
  }

  Future<void> _createRequest() async {
    if (_selectedServiceId == null || _selectedServiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a procedure first')));
      return;
    }
    _selectedServiceData ??= (await FirebaseFirestore.instance
            .collection('services')
            .doc(_selectedServiceId!)
            .get())
        .data();
    final svc      = _selectedServiceData ?? const <String, dynamic>{};
    final nameKey  = (svc['name'] ?? '').toString();
    final label    = nameKey.isNotEmpty ? nameKey : _selectedServiceId!;
    final dur      = svc['durationMin'] is num
        ? (svc['durationMin'] as num).toInt()
        : 30;

    await _brRepo.upsertRequest(
      workerId: _selectedWorkerId,
      clientId: widget.clientId,
      serviceId: _selectedServiceId!,
      serviceNameKey: nameKey,
      serviceNameLabel: label,
      durationMin: dur,
      exactSlots: const [],
      preferredDays: List<String>.from(_selectedDayKeys),
      preferredTimeRanges: List<Map<String, int>>.from(_selectedRanges),
    );
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.clientId)
        .set({
      'bookingRequestActive': true,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() {
      _looking = true;
      _showAddRequest = false;
      _selectedDayKeys.clear();
      _selectedRanges.clear();
      _selectedWorkerId    = null;
      _selectedServiceId   = null;
      _selectedServiceData = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request created')));
  }

  // ── Appointment card ─────────────────────────────────────────────────────────

  Widget _apptCard(Map<String, dynamic> d) {
    final ts      = d['appointmentDate'];
    final date    = ts is Timestamp ? ts.toDate() : null;
    final dateStr = date != null
        ? DateTimeUtils.formatYyyyMmDdToDdMmYyyy(DateTimeUtils.yyyymmdd(date))
        : (d['date'] ?? '').toString();
    final timeStr  = date != null
        ? DateTimeUtils.hhmmFromMinutes(date.hour * 60 + date.minute)
        : '';
    final service = (d['serviceName'] ?? d['service'] ?? '').toString();
    final status  = (d['status'] ?? '').toString();

    final statusColor = {
      'scheduled': kPurple,
      'done':      Colors.green,
      'cancelled': Colors.red,
      'noShow':    Colors.orange,
    }[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
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
                const SizedBox(height: 4),
                Text(
                  '$dateStr${timeStr.isNotEmpty ? '  ·  $timeStr' : ''}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: kPurple)));
    }

    final name    = _fullName();
    final contact = _contactLine();

    return Scaffold(
      body: Column(
        children: [
          // Header
          AppGradientHeader(
            title: name,
            subtitle: contact.isNotEmpty ? contact : 'Client profile',
          ),

          // Tab bar
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: kPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPurple,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPastTab(),
              ],
            ),
          ),

          // Bottom actions
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Upcoming tab ─────────────────────────────────────────────────────────────

  Widget _buildUpcomingTab() {
    final upcomingStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('clientId', isEqualTo: widget.clientId)
        .where('status', isEqualTo: 'scheduled')
        .where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('appointmentDate')
        .limit(50)
        .snapshots();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking request toggle
          AppSectionCard(
            title: 'Booking request',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _looking ? 'Looking for appointment' : 'Not looking',
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
                    await FirebaseFirestore.instance
                        .collection('clients')
                        .doc(widget.clientId)
                        .set({
                      'bookingRequestActive': true,
                      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                  },
                ),
              ],
            ),
          ),

          if (_looking) ...[
            const SizedBox(height: 12),
            StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _brRepo.streamActiveRequestsForClient(widget.clientId),
              builder: (_, snap) {
                final docs = snap.data ?? [];
                return Column(
                  children: docs
                      .map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BookingRequestCard(
                              requestId: d.id,
                              br: d.data(),
                              purple: kPurple,
                              onDelete: () async =>
                                  _brRepo.deleteRequest(d.id),
                              onEditRequest: () {},
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            _panelHeader(
              title: 'Add booking request',
              open: _showAddRequest,
              onTap: () =>
                  setState(() => _showAddRequest = !_showAddRequest),
            ),
            if (_showAddRequest) ...[
              const SizedBox(height: 10),
              AppSectionCard(
                title: 'New request details',
                child: BookingRequestCreateForm(
                  selectedWorkerId: _selectedWorkerId,
                  onWorkerChanged: (v) =>
                      setState(() => _selectedWorkerId = v),
                  selectedServiceId: _selectedServiceId,
                  onServiceChanged: (sid) async {
                    if (sid == null || sid.isEmpty) {
                      setState(() {
                        _selectedServiceId = null;
                        _selectedServiceData = null;
                      });
                      return;
                    }
                    final doc = await FirebaseFirestore.instance
                        .collection('services')
                        .doc(sid)
                        .get();
                    setState(() {
                      _selectedServiceId = sid;
                      _selectedServiceData = doc.data();
                    });
                  },
                  selectedDays: _selectedDayKeys,
                  selectedRanges: _selectedRanges,
                  onAddDay: _addDay,
                  onRemoveDayKey: (k) =>
                      setState(() => _selectedDayKeys.remove(k)),
                  onAddRange: _addRange,
                  onRemoveRangeAt: (i) {
                    if (i < 0 || i >= _selectedRanges.length) return;
                    setState(() => _selectedRanges.removeAt(i));
                  },
                  onCreate: _createRequest,
                  purple: kPurple,
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),
          const Text('Upcoming appointments',
              style:
                  TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: upcomingStream,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: kPurple));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Text('No upcoming appointments.',
                    style: TextStyle(color: Colors.grey[700]));
              }
              return Column(
                  children: docs.map((d) => _apptCard(d.data())).toList());
            },
          ),

          const SizedBox(height: 16),
          _buildEditPanel(),
        ],
      ),
    );
  }

  // ── Past tab ─────────────────────────────────────────────────────────────────

  Widget _buildPastTab() {
    final pastStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('clientId', isEqualTo: widget.clientId)
        .where('appointmentDate', isLessThan: Timestamp.now())
        .orderBy('appointmentDate', descending: true)
        .limit(100)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: pastStream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPurple));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
              child: Text('No past appointments.',
                  style: TextStyle(color: Colors.grey[700])));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _apptCard(docs[i].data()),
        );
      },
    );
  }

  // ── Edit panel ───────────────────────────────────────────────────────────────

  Widget _buildEditPanel() {
    return Column(
      children: [
        _panelHeader(
          title: 'Edit client',
          open: _editOpen,
          onTap: () => setState(() => _editOpen = !_editOpen),
        ),
        if (_editOpen) ...[
          const SizedBox(height: 10),
          AppSectionCard(
            title: 'Client data',
            child: Column(
              children: [
                TextField(
                    controller: _fnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'First name',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: _lnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Last name',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                          controller: _countryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Country code',
                              border: OutlineInputBorder())),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder())),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: _igCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Instagram',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          title: const Text('Confirm edit'),
                          content:
                              const Text('Save changes to this client?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dctx, false),
                                child: const Text('No')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kPurple),
                              onPressed: () => Navigator.pop(dctx, true),
                              child: const Text('Yes',
                                  style:
                                      TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await _saveClientEdits();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Client updated')));
                      setState(() => _editOpen = false);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save client'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    title: const Text('Delete client?'),
                    content: const Text(
                        'This will delete the client document. Continue?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dctx, false),
                          child: const Text('No')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(dctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await _deleteClient();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client deleted')));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context
                    .read<AdminNavProvider>()
                    .goToBookingWithClient(widget.clientId);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.edit_calendar_outlined,
                  color: Colors.white),
              label: const Text('New appointment',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: collapsible panel header ────────────────────────────────────────

  Widget _panelHeader(
      {required String title,
      required bool open,
      required VoidCallback onTap}) {
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
            Expanded(
                child: Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w900))),
            Icon(open ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
