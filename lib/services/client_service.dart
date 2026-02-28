// lib/services/client_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/utils/string_utils.dart';

class ClientService {
  ClientService(this._db);

  final FirebaseFirestore _db;

  String normalizeInstagram(String raw) {
    var v = raw.trim().toLowerCase();
    if (v.startsWith('@')) v = v.substring(1);
    v = v.replaceAll(RegExp(r'\s+'), '');
    return v;
  }

  // ✅ NO TOCAR: tu search está perfecto (lo dejamos tal cual)
  List<String> buildSearchTokens({
    required String firstName,
    required String lastName,
    required int country,
    required int phone,
    required String instagram,
  }) {
    final tokens = <String>{};

    void addParts(String s) {
      final v = s.toLowerCase().trim();
      if (v.isEmpty) return;
      tokens.add(v);
      for (final part in v.split(RegExp(r'\s+'))) {
        if (part.trim().isNotEmpty) tokens.add(part.trim());
      }
    }

    addParts(firstName);
    addParts(lastName);
    addParts('$firstName $lastName');

    if (country > 0) tokens.add(country.toString());
    if (phone > 0) tokens.add(phone.toString());
    if (country > 0 && phone > 0) tokens.add('$country$phone');

    if (instagram.isNotEmpty) tokens.add(instagram);

    return tokens.toList();
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ NEW: ID formato first_last_country_phone (+ sufijo si colisiona)
  // ─────────────────────────────────────────────────────────────

  String _slug(String input) => StringUtils.slug(input, emptyFallback: 'x');

  String _buildBaseClientId({
    required String firstName,
    required String lastName,
    required int country,
    required int phone,
  }) {
    final fn = _slug(firstName);
    final ln = _slug(lastName);
    final c = country > 0 ? country.toString() : '0';
    final p = phone > 0 ? phone.toString() : '0';
    return '${fn}_${ln}_${c}_$p';
  }

  Future<String> _buildUniqueClientIdFromBase(String base) async {
    final baseSnap = await _db.collection('clients').doc(base).get();
    if (!baseSnap.exists) return base;

    // base_2, base_3, ... (sin random)
    for (int i = 2; i <= 500; i++) {
      final candidate = '${base}_$i';
      final snap = await _db.collection('clients').doc(candidate).get();
      if (!snap.exists) return candidate;
    }

    throw Exception("Too many clients with same name/country/phone");
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIND DUPLICATES (phone/ig -> lista, name -> lista)
  // ─────────────────────────────────────────────────────────────

  Future<List<_ClientHit>> _findClientsByPhone({
    required int country,
    required int phone,
    int limit = 10,
  }) async {
    if (country <= 0 || phone <= 0) return const [];

    final q = await _db
        .collection('clients')
        .where('country', isEqualTo: country)
        .where('phone', isEqualTo: phone)
        .limit(limit)
        .get();

    return q.docs.map((d) => _ClientHit(id: d.id, data: d.data())).toList(growable: false);
  }

  Future<List<_ClientHit>> _findClientsByInstagram({
    required String instagramNormalized,
    int limit = 10,
  }) async {
    if (instagramNormalized.isEmpty) return const [];

    final q = await _db
        .collection('clients')
        .where('instagram', isEqualTo: instagramNormalized)
        .limit(limit)
        .get();

    return q.docs.map((d) => _ClientHit(id: d.id, data: d.data())).toList(growable: false);
  }

  Future<List<_ClientHit>> _findClientsByNameTokens({
    required String firstName,
    required String lastName,
    int limit = 10,
  }) async {
    final fn = firstName.trim();
    final ln = lastName.trim();
    if (fn.isEmpty || ln.isEmpty) return const [];

    final fullLower = '${fn.toLowerCase()} ${ln.toLowerCase()}'.trim();
    if (fullLower.isEmpty) return const [];

    // ✅ usamos tu campo search (array) -> array-contains exact token
    final q = await _db.collection('clients').where('search', arrayContains: fullLower).limit(limit).get();

    return q.docs.map((d) => _ClientHit(id: d.id, data: d.data())).toList(growable: false);
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ UI helpers (card igual al diseño de cliente seleccionado)
  // ─────────────────────────────────────────────────────────────

  Widget _clientPreviewCard(_ClientHit hit, {bool selected = false}) {
    final d = hit.data;
    final fn = (d['firstName'] ?? '').toString();
    final ln = (d['lastName'] ?? '').toString();

    final c = (d['country'] is num) ? (d['country'] as num).toInt() : 0;
    final p = (d['phone'] is num) ? (d['phone'] as num).toInt() : 0;
    final ig = (d['instagram'] ?? '').toString();

    final contact = [
      (c > 0 && p > 0) ? "+$c $p" : null,
      ig.isNotEmpty ? "@$ig" : null,
    ].whereType<String>().join(' • ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff721c80).withOpacity(selected ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? const Color(0xff721c80).withOpacity(0.55)
              : const Color(0xff721c80).withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$fn $ln".trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            contact,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Future<_DuplicatePickResult?> _showDuplicatesPicker({
    required BuildContext context,
    required String title,
    required String message,
    required List<_ClientHit> hits,
    required String primaryButtonText,
    required String secondaryButtonText,
    Color primaryColor = Colors.amber,
  }) async {
    int selectedIndex = 0;

    return showDialog<_DuplicatePickResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    ...List.generate(hits.length, (i) {
                      final h = hits[i];
                      final isSel = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setLocal(() => selectedIndex = i),
                          child: _clientPreviewCard(h, selected: isSel),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, _DuplicatePickResult.cancel),
                  child: Text(secondaryButtonText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () => Navigator.pop(
                    dialogCtx,
                    _DuplicatePickResult(
                      pickedId: hits[selectedIndex].id,
                      pickedData: hits[selectedIndex].data,
                    ),
                  ),
                  child: Text(primaryButtonText, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_DuplicateDecision?> _showPhoneIgDecisionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required List<_ClientHit> hits,
  }) async {
    int selectedIndex = 0;

    return showDialog<_DuplicateDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
                    ...List.generate(hits.length, (i) {
                      final isSel = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setLocal(() => selectedIndex = i),
                          child: _clientPreviewCard(hits[i], selected: isSel),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, _DuplicateDecision.useExisting(selectedIndex)),
                  child: const Text("Use existing"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: () => Navigator.pop(dialogCtx, _DuplicateDecision.createAnyway),
                  child: const Text("Create anyway", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ MAIN: create or get with:
  // - alerta por phone/ig (muestra cards)
  // - alerta por nombre (muestra cards)
  // - ID first_last_country_phone (+ sufijo si existe)
  // ─────────────────────────────────────────────────────────────
  Future<ClientUpsertResult> createOrGetClient({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required int country,
    required int phone,
    required String instagramRaw,
  }) async {
    final fn = firstName.trim();
    final ln = lastName.trim();
    final ig = normalizeInstagram(instagramRaw);

    final hasPhone = country > 0 && phone > 0;
    if (!hasPhone && ig.isEmpty) {
      throw Exception("Phone or Instagram is required");
    }

    // 0) DUPLICATE NAME CHECK (forzado)
    //    -> te enseña quién existe con ese nombre (cards)
    final nameHits = await _findClientsByNameTokens(firstName: fn, lastName: ln, limit: 10);
    if (nameHits.isNotEmpty) {
      final res = await _showDuplicatesPicker(
        context: context,
        title: "Name already exists",
        message: "There are clients with the same first name and last name.\nCheck below to avoid duplicates.",
        hits: nameHits,
        primaryButtonText: "Create anyway",
        secondaryButtonText: "Go back",
        primaryColor: Colors.amber,
      );

      if (res == null || res == _DuplicatePickResult.cancel) {
        // usuario quiso volver y cambiar nombre
        throw Exception("Duplicate name");
      }
      // si eligió Create anyway -> seguimos
    }

    // 1) DUPLICATE CONTACT CHECK (phone + ig), con cards y selección
    final phoneHits = await _findClientsByPhone(country: country, phone: phone, limit: 10);
    final igHits = await _findClientsByInstagram(instagramNormalized: ig, limit: 10);

    // Merge (sin repetir IDs)
    final merged = <String, _ClientHit>{};
    for (final h in phoneHits) merged[h.id] = h;
    for (final h in igHits) merged[h.id] = h;
    final contactHits = merged.values.toList(growable: false);

    if (contactHits.isNotEmpty) {
      final decision = await _showPhoneIgDecisionDialog(
        context: context,
        title: "Phone/Instagram already exists",
        message: "This contact is already used by:",
        hits: contactHits,
      );

      if (decision == null) {
        throw Exception("Cancelled");
      }

      if (decision.kind == _DuplicateDecisionKind.useExisting) {
        final picked = contactHits[decision.selectedIndex ?? 0];
        final exData = picked.data;

        final exFn = (exData['firstName'] ?? '').toString();
        final exLn = (exData['lastName'] ?? '').toString();
        final exCountry = (exData['country'] is num) ? (exData['country'] as num).toInt() : 0;
        final exPhone = (exData['phone'] is num) ? (exData['phone'] as num).toInt() : 0;
        final exIg = (exData['instagram'] ?? '').toString();

        return ClientUpsertResult(
          clientId: picked.id,
          firstName: exFn,
          lastName: exLn,
          country: exCountry,
          phone: exPhone,
          instagram: exIg,
          createdNew: false,
        );
      }

      // createAnyway -> seguimos creando otro con ID único (con sufijo si hace falta)
    }

    // 2) CREAR NUEVO con ID formato first_last_country_phone (+ sufijo si existe)
    final baseId = _buildBaseClientId(
      firstName: fn,
      lastName: ln,
      country: country,
      phone: phone,
    );
    final id = await _buildUniqueClientIdFromBase(baseId);

    final searchTokens = buildSearchTokens(
      firstName: fn,
      lastName: ln,
      country: country,
      phone: phone,
      instagram: ig,
    );

    await _db.collection('clients').doc(id).set(
      {
        'firstName': fn,
        'lastName': ln,
        'country': country,
        'phone': phone,
        'instagram': ig,
        'search': searchTokens,

        // timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // booking request defaults (compatibilidad)
        'bookingRequestActive': false,
        'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),

        // stats (solo contadores + última cita)
        'stats': {
          'totalAppointments': 0,
          'totalCancelled': 0,
          'totalNoShow': 0,
          'lastAppointmentAt': null,
          'lastAppointmentSummary': '',
        },
      },
      SetOptions(merge: true),
    );

    return ClientUpsertResult(
      clientId: id,
      firstName: fn,
      lastName: ln,
      country: country,
      phone: phone,
      instagram: ig,
      createdNew: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Internal models
// ─────────────────────────────────────────────────────────────

class _ClientHit {
  final String id;
  final Map<String, dynamic> data;
  const _ClientHit({required this.id, required this.data});
}

enum _DuplicateDecisionKind { useExisting, createAnyway }

class _DuplicateDecision {
  final _DuplicateDecisionKind kind;
  final int? selectedIndex;

  const _DuplicateDecision._(this.kind, this.selectedIndex);

  factory _DuplicateDecision.useExisting(int selectedIndex) =>
      _DuplicateDecision._(_DuplicateDecisionKind.useExisting, selectedIndex);

  static const createAnyway = _DuplicateDecision._(_DuplicateDecisionKind.createAnyway, null);
}

class _DuplicatePickResult {
  final String? pickedId;
  final Map<String, dynamic>? pickedData;

  const _DuplicatePickResult({required this.pickedId, required this.pickedData});

  static const cancel = _DuplicatePickResult(pickedId: null, pickedData: null);
}

class ClientUpsertResult {
  final String clientId;
  final String firstName;
  final String lastName;
  final int country;
  final int phone;
  final String instagram;
  final bool createdNew;

  ClientUpsertResult({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.phone,
    required this.instagram,
    required this.createdNew,
  });

  String get fullName => "$firstName $lastName".trim();
}
