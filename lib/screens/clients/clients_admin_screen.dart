// lib/screens/clients/clients_admin_screen.dart
//
// Perf(commit 9): batch prefetch next appointments
//  • En lugar de 1 query por card visible (FutureBuilder individual),
//    se hace 1 sola query para todos los IDs visibles en pantalla a la vez.
//  • _prefetchNextAppts(ids) carga los próximos appointments de todos los
//    clientes de una lista en una sola roundtrip a Firestore.
//  • El cache sigue existiendo para no repetir queries en rebuilds.

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

class ClientsAdminScreen extends StatefulWidget {
  const ClientsAdminScreen({super.key});

  @override
  State<ClientsAdminScreen> createState() => _ClientsAdminScreenState();
}

class _ClientsAdminScreenState extends State<ClientsAdminScreen> {
  final _searchCtrl = TextEditingController();
  late final ClientService _clientService;

  // Cache clientId → label ('' = sin turno próximo)
  // Se llena en lote al cargar la lista — 1 query para todos los IDs visibles.
  final Map<String, String> _nextApptCache = {};
  // IDs ya prefetcheados (evita repetir la query batch en cada rebuild)
  final Set<String> _prefetchedIds = {};

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

  // ── Next appointment — batch prefetch ────────────────────────────────────────
  //
  // En lugar de 1 query por card (el patrón anterior), cargamos los próximos
  // appointments de TODOS los clientIds visibles en una sola query usando
  // whereIn. Firestore permite hasta 30 IDs por whereIn.
  //
  // Se llama una vez cuando el StreamBuilder recibe datos nuevos.
  // El cache evita repetir la query en rebuilds posteriores.

  String _formatApptLabel(DateTime dt) {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '\${wd[(dt.weekday - 1).clamp(0, 6)]} '
        '\${DateTimeUtils.formatYyyyMmDdToDdMmYyyy(DateTimeUtils.yyyymmdd(dt))} · '
        '\${DateTimeUtils.hhmmFromMinutes(dt.hour * 60 + dt.minute)}';
  }

  Future<void> _prefetchNextAppts(List<String> clientIds) async {
    // Solo los IDs que no están en cache todavía
    final missing = clientIds
        .where((id) => !_prefetchedIds.contains(id))
        .toList();
    if (missing.isEmpty) return;

    // Marcar como prefetcheados antes de la query (evita doble-fetch en rapid rebuilds)
    _prefetchedIds.addAll(missing);

    // Firestore whereIn: max 30 por chunk
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
            .limit(chunk.length * 2) // max 2 upcoming per client in one query
            .get();

        // Para cada clientId del chunk, queda el appointment más próximo
        final Map<String, DateTime> earliest = {};
        final Map<String, String> services = {};
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

        // Poblar cache
        for (final id in chunk) {
          if (earliest.containsKey(id)) {
            _nextApptCache[id] = _formatApptLabel(earliest[id]!);
          } else {
            _nextApptCache[id] = '';
          }
        }

        if (mounted) setState(() {});
      } catch (_) {
        // Si falla un chunk, dejamos los IDs sin label (se muestran sin pill)
        for (final id in chunk) {
          _nextApptCache.putIfAbsent(id, () => '');
        }
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _openClientProfile(String clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ClientProfileScreen(clientId: clientId)),
    ).then((_) {
      // Invalida cache de este cliente al volver (puede haber cambiado)
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

    // Limit 100: carga inicial rápida. Con búsqueda activa se filtra en memoria.
    // Si se necesitan más clientes, aumentar el límite o implementar cursor pagination.
    final stream = FirebaseFirestore.instance
        .collection('clients')
        .orderBy('updatedAt', descending: true)
        .limit(100)
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

          // Dispara el batch prefetch para todos los IDs de la lista filtrada.
          // unawaited — no bloquea el build. El setState() dentro de
          // _prefetchNextAppts actualiza las pills cuando llegan los datos.
          final idsToFetch = filtered.map((d) => d.id).toList();
          Future.microtask(() => _prefetchNextAppts(idsToFetch));

          // CustomScrollView: header fijo + lista virtualizada (solo renderiza
          // los items visibles en pantalla, no los 100 de golpe)
          return CustomScrollView(
            slivers: [
              // Header con search bar
              SliverToBoxAdapter(
                child: AppGradientHeader(
                  title: 'Clients',
                  subtitle: 'Search by name / phone / instagram',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openCreateClientDialog,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.black.withOpacity(0.35)),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_add_alt_1_rounded,
                                    color: Color(0xff721c80), size: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading / error / empty
              if (snap.connectionState == ConnectionState.waiting &&
                  docs.isEmpty)
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
                // SliverList virtualizado. El prefetch batch ya pobló el cache
                // antes de llegar aquí (se dispara en el StreamBuilder builder).
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                  sliver: SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d      = filtered[i];
                      final data   = d.data();
                      final hasReq = data['bookingRequestActive'] == true;
                      // Lee del cache directamente — sin FutureBuilder individual
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
                                  background: const Color(0xff721c80)
                                      .withOpacity(0.10),
                                  borderColor: const Color(0xff721c80)
                                      .withOpacity(0.25),
                                  child: const Icon(
                                      Icons.notifications_active_outlined,
                                      size: 16,
                                      color: Color(0xff721c80)),
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

// ── Create client dialog (sin cambios) ───────────────────────────────────────

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Expanded(child: Text('Create client',
              style: TextStyle(fontWeight: FontWeight.w900))),
          IconButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _fnCtrl,
                  decoration: const InputDecoration(labelText: 'First name',
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(controller: _lnCtrl,
                  decoration: const InputDecoration(labelText: 'Last name',
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required' : null),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(flex: 2, child: TextFormField(
                    controller: _countryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Country code',
                        border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(flex: 4, child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Phone',
                        border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 10),
              TextFormField(controller: _igCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Instagram (optional)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Text('Phone OR Instagram required',
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
                    const SnackBar(content: Text('Phone or Instagram required')));
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client created')));
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}
