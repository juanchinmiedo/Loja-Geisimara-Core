// lib/screens/clients/clients_admin_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/components/ui/app_gradient_header.dart';
import 'package:salon_app/components/ui/app_pill.dart';
import 'package:salon_app/components/client_card.dart';
import 'package:salon_app/screens/clients/clients_profile_screen.dart';
import 'package:salon_app/services/client_service.dart';
import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/provider/locale_provider.dart';
import 'package:salon_app/services/audit_service.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/components/ui/header_action_button.dart';

class ClientsAdminScreen extends StatefulWidget {
  const ClientsAdminScreen({super.key});

  @override
  State<ClientsAdminScreen> createState() => _ClientsAdminScreenState();
}

class _ClientsAdminScreenState extends State<ClientsAdminScreen> {
  static const _purple = Color(0xff721c80);

  final _searchCtrl = TextEditingController();
  late final ClientService _clientService;

  final Map<String, String> _nextApptCache = {};
  final Set<String> _prefetchedIds = {};

  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.read<LocaleProvider>().locale;
    if (_lastLocale != null && _lastLocale != locale) {
      _nextApptCache.clear();
      _prefetchedIds.clear();
    }
    _lastLocale = locale;
  }

  @override
  void initState() {
    super.initState();
    _clientService = ClientService(FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatApptLabel(DateTime dt, S s) {
    final wd = [s.weekdayMon, s.weekdayTue, s.weekdayWed, s.weekdayThu,
                s.weekdayFri, s.weekdaySat, s.weekdaySun];
    return '${wd[(dt.weekday - 1).clamp(0, 6)]} '
        '${DateTimeUtils.formatYyyyMmDdToDdMmYyyy(DateTimeUtils.yyyymmdd(dt))} · '
        '${DateTimeUtils.hhmmFromMinutes(dt.hour * 60 + dt.minute)}';
  }

  Future<void> _prefetchNextAppts(List<String> clientIds, S s) async {
    final missing = clientIds
        .where((id) => !_prefetchedIds.contains(id))
        .toList();
    if (missing.isEmpty) return;

    _prefetchedIds.addAll(missing);

    const chunkSize = 30;
    for (int i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.sublist(i, (i + chunkSize).clamp(0, missing.length));
      try {
        final snap = await FirebaseFirestore.instance
            .collection('appointments')
            .where('clientId', whereIn: chunk)
            .where('status', isEqualTo: 'scheduled')
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('appointmentDate')
            .limit(chunk.length * 2)
            .get();

        final Map<String, DateTime> earliest = {};
        for (final doc in snap.docs) {
          final data     = doc.data();
          final clientId = (data['clientId'] ?? '').toString();
          final ts       = data['appointmentDate'];
          if (ts is! Timestamp) continue;
          final dt = ts.toDate();
          if (!earliest.containsKey(clientId) ||
              dt.isBefore(earliest[clientId]!)) {
            earliest[clientId] = dt;
          }
        }

        for (final id in chunk) {
          if (earliest.containsKey(id)) {
            _nextApptCache[id] = _formatApptLabel(earliest[id]!, s);
          } else {
            _nextApptCache[id] = '';
          }
        }

        if (mounted) setState(() {});
      } catch (_) {
        for (final id in chunk) {
          _nextApptCache.putIfAbsent(id, () => '');
        }
      }
    }
  }

  void _openClientProfile(String clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ClientProfileScreen(clientId: clientId)),
    ).then((_) {
      _nextApptCache.remove(clientId);
      _prefetchedIds.remove(clientId);
      if (mounted) setState(() {});
    });
  }

  Future<void> _openCreateClientDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateClientDialog(clientService: _clientService),
    );
  }

  // ── Add client button — mismo estilo que la campana de home ──────────────────

  Widget _buildAddClientButton() {
    return HeaderActionButton(
      icon: Icons.person_add_alt_1_rounded,
      onTap: _openCreateClientDialog,
    );
  }

  // ── Header child: buscador + stats ────────────────────────────────────────────

  Widget _buildHeaderChild(S s, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final total    = docs.length;
    final looking  = docs.where((d) => d.data()['bookingRequestActive'] == true).length;
    final withAppt = _nextApptCache.values.where((v) => v.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buscador + botón add (alineados)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.95),
                  prefixIcon: const Icon(Icons.search),
                  hintText: s.searchHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _buildAddClientButton(),
          ],
        ),

        // Stats pills
        if (total > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              _statPill(Icons.people_alt_outlined, '$total', Colors.white),
              const SizedBox(width: 8),
              _statPill(Icons.notifications_active_outlined, '$looking', Colors.white),
              const SizedBox(width: 8),
              _statPill(Icons.event_available_outlined, '$withAppt', Colors.white),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statPill(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withOpacity(0.85)),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.95),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s   = S.of(context);
    final nav = context.watch<AdminNavProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final openId = nav.openClientId;
      if (openId != null) {
        _openClientProfile(openId);
        context.read<AdminNavProvider>().clearOpenClient();
      }
    });

    final stream = FirebaseFirestore.instance
        .collection('clients')
        .orderBy('updatedAt', descending: true)
        .limit(250)
        .snapshots();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          final q    = _searchCtrl.text.trim().toLowerCase();

          final filtered = q.isEmpty
              ? docs
              : docs.where((d) {
                  final search = (d.data()['search'] as List<dynamic>?)
                          ?.map((e) => e.toString().toLowerCase())
                          .toList() ?? [];
                  return search.any((t) => t.contains(q));
                }).toList();

          filtered.sort((a, b) {
            final av = a.data()['bookingRequestActive'] == true ? 1 : 0;
            final bv = b.data()['bookingRequestActive'] == true ? 1 : 0;
            return bv.compareTo(av);
          });

          final idsToFetch = filtered.map((d) => d.id).toList();
          Future.microtask(() => _prefetchNextAppts(idsToFetch, s));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppGradientHeader(
                  title: s.clientsTab,
                  height: 195,
                  child: _buildHeaderChild(s, docs),
                ),
              ),

              if (snap.connectionState == ConnectionState.waiting && docs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.purple)),
                  ),
                )
              else if (snap.hasError)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Text(s.noMatches,
                        style: TextStyle(color: Colors.grey[700])),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d      = filtered[i];
                      final data   = d.data();
                      final hasReq = data['bookingRequestActive'] == true;
                      final nextLabel = _nextApptCache[d.id];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClientCard(
                          data: data,
                          showChevron: true,
                          nextAppointmentLabel:
                              (nextLabel != null && nextLabel.isNotEmpty)
                                  ? nextLabel
                                  : null,
                          trailingBeforeChevron: hasReq
                              ? AppPill(
                                  background: _purple.withOpacity(0.10),
                                  borderColor: _purple.withOpacity(0.25),
                                  child: const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 16,
                                      color: _purple),
                                )
                              : null,
                          onTap: () => _openClientProfile(d.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Create client dialog ──────────────────────────────────────────────────────

class _CreateClientDialog extends StatefulWidget {
  const _CreateClientDialog({required this.clientService});
  final ClientService clientService;

  @override
  State<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<_CreateClientDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _fnCtrl      = TextEditingController();
  final _lnCtrl      = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _igCtrl      = TextEditingController();
  bool _saving       = false;

  int _i(String s) => int.tryParse(s.trim()) ?? 0;

  @override
  void dispose() {
    _fnCtrl.dispose(); _lnCtrl.dispose(); _countryCtrl.dispose();
    _phoneCtrl.dispose(); _igCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(child: Text(s.createClient, style: const TextStyle(fontWeight: FontWeight.w900))),
          IconButton(onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _fnCtrl,
                  decoration: InputDecoration(labelText: s.firstNameLabel,
                  border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                  ? s.required : null),
              const SizedBox(height: 10),
              TextFormField(controller: _lnCtrl,
                  decoration: InputDecoration(labelText: s.lastNameLabel,
                  border: const OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ?
                  s.required : null),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(flex: 2, child: TextFormField(
                    controller: _countryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.countryCode,
                    border: const OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(flex: 4, child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.phoneLabel,
                    border: const OutlineInputBorder()))),
              ]),
              const SizedBox(height: 10),
              TextFormField(controller: _igCtrl,
                  decoration: InputDecoration(
                  labelText: s.instagramOptionalLabel,
                  border: const OutlineInputBorder())),
              const SizedBox(height: 10),
              Text(s.phoneOrInstagramRequiredMsg,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12)),
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
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _saving ? null : () async {
              if (_formKey.currentState?.validate() != true) return;
              final ctry = _i(_countryCtrl.text);
              final ph   = _i(_phoneCtrl.text);
              final ig   = widget.clientService.normalizeInstagram(_igCtrl.text);
              if (ctry == 0 && ph == 0 && ig.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.phoneOrInstagramRequiredMsg)));
                return;
              }
              setState(() => _saving = true);
              try {
                await widget.clientService.createOrGetClient(
                  context: context,
                  firstName: _fnCtrl.text.trim(),
                  lastName:  _lnCtrl.text.trim(),
                  country: ctry, phone: ph,
                  instagramRaw: _igCtrl.text,
                );
                if (!mounted) return;

                // ── Audit log ─────────────────────────────────────────────
                final _name = '\${_fnCtrl.text.trim()} \${_lnCtrl.text.trim()}'.trim();
                final _wid  = context.read<UserProvider>().workerId;
                unawaited(AuditService().logClientCreated(
                  clientId: '',
                  clientName: _name,
                  performerWorkerId: _wid,
                ));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s.clientCreated)));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(s.create, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}
