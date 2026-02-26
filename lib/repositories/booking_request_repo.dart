import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

class BookingRequestRepo {
  BookingRequestRepo(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _req =>
      db.collection('booking_requests');

  /// ✅ Notificaciones tipo “lock-screen”
  ///
  /// Antes estaban en `admin_alerts`, pero tus Firestore Rules NO permiten esa
  /// colección => PERMISSION_DENIED.
  ///
  /// Para no tocar rules, las guardamos aquí (rules ya lo permiten):
  ///   /clients/__system__/history/{entryId}
  CollectionReference<Map<String, dynamic>> get _alerts => db
      .collection('clients')
      .doc('__system__')
      .collection('history');

  Future<void> _safeAddAlert(Map<String, dynamic> data) async {
    try {
      await _alerts.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Las alertas nunca deben romper flujos principales.
    }
  }

  DocumentReference<Map<String, dynamic>> _clientRef(String clientId) =>
      db.collection('clients').doc(clientId);

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      streamActiveRequestsForClient(String clientId) {
    return _req
        .where('clientId', isEqualTo: clientId)
        .where('active', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getActiveRequestsForClient(String clientId) async {
    final snap = await _req
        .where('clientId', isEqualTo: clientId)
        .where('active', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs;
  }

  Future<void> upsertRequest({
    required String clientId,
    String? workerId, // ✅ null => any worker
    required List<Timestamp> exactSlots,
    required List<String> preferredDays,
    required List<Map<String, int>> preferredTimeRanges,
    required String notes,
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = _req.doc();

    await db.runTransaction((tx) async {
      tx.set(doc, {
        'clientId': clientId,

        // ✅ SIEMPRE presente (null = any worker)
        'workerId': workerId,

        'active': true,
        'createdAt': now,
        'updatedAt': now,
        'exactSlots': exactSlots,
        'preferredDays': preferredDays,
        'preferredTimeRanges': preferredTimeRanges,
        'notes': notes,
      });

      tx.set(_clientRef(clientId), {
        'bookingRequestActive': true,
        'bookingRequestUpdatedAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateRequestNotes({
    required String requestId,
    required String notes,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = _req.doc(requestId);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final clientId = (data?['clientId'] ?? '').toString();

      tx.set(ref, {
        'notes': notes,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (clientId.isNotEmpty) {
        tx.set(_clientRef(clientId), {
          'bookingRequestUpdatedAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> deleteRequest(String requestId) async {
    final now = FieldValue.serverTimestamp();
    final ref = _req.doc(requestId);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final clientId = (data?['clientId'] ?? '').toString();

      tx.delete(ref);

      if (clientId.isNotEmpty) {
        final rest = await _req
            .where('clientId', isEqualTo: clientId)
            .where('active', isEqualTo: true)
            .get();

        tx.set(_clientRef(clientId), {
          'bookingRequestActive': rest.docs.isNotEmpty,
          'bookingRequestUpdatedAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> deleteAllActiveForClient(String clientId) async {
    final docs = await getActiveRequestsForClient(clientId);
    final batch = db.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  /// ✅ Cuando se crea un appointment para un cliente:
  /// - Si YA existían booking requests activas de ese cliente, se borran.
  /// - Si NO existían, no toca nada.
  /// - Siempre deja al cliente libre para crear requests nuevas después.
  /// - Crea una notificación estética en /clients/__system__/history.
  Future<int> deleteExistingRequestsBecauseAppointmentWasCreated({
    required String clientId,
    required String appointmentId,
    DateTime? appointmentDate,
    String? serviceName,
  }) async {
    final docs = await getActiveRequestsForClient(clientId);
    if (docs.isEmpty) return 0;

    final batch = db.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }

    // Actualiza el cliente (así no quedan flags viejos)
    batch.set(
      _clientRef(clientId),
      {
        'bookingRequestActive': false,
        'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Notificación
    final when = appointmentDate;
    final title = 'Booking request removed';
    final body =
        'Deleted ${docs.length} request(s) because an appointment was created'
        '${serviceName != null && serviceName.trim().isNotEmpty ? ' ($serviceName)' : ''}'
        '${when != null ? ' for ${BookingRequestUtils.yyyymmdd(when)}' : ''}.';

    batch.set(_alerts.doc(), {
      'type': 'booking_request_removed_by_appointment',
      'clientId': clientId,
      'appointmentId': appointmentId,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return docs.length;
  }

  /// ✅ Cuando un appointment se mueve / cancela / se borra, puede quedar un hueco libre.
  /// Esta función revisa booking requests activas y crea una notificación con "matches".
  ///
  /// NOTA: No reserva nada automáticamente (solo concluye "hay match posible").
  Future<int> notifyIfFreedSlotMatchesRequests({
    required DateTime freedStart,
    required int freedDurationMin,
    required String workerId,
    required String reason, // edit | cancelled | noShow | deletePermanent
    String? sourceAppointmentId,
  }) async {
    if (freedDurationMin <= 0) return 0;

    final freedEnd = freedStart.add(Duration(minutes: freedDurationMin));
    final dayKey = BookingRequestUtils.yyyymmdd(freedStart);
    final startMin = freedStart.hour * 60 + freedStart.minute;
    final endMin = freedEnd.hour * 60 + freedEnd.minute;

    // Firestore no soporta OR directo, así que hacemos 2 queries y merge.
    final qAnyWorker = await _req
        .where('active', isEqualTo: true)
        .where('workerId', isNull: true)
        .get();
    final qSameWorker = await _req
        .where('active', isEqualTo: true)
        .where('workerId', isEqualTo: workerId)
        .get();

    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in qAnyWorker.docs) merged[d.id] = d;
    for (final d in qSameWorker.docs) merged[d.id] = d;
    final all = merged.values.toList(growable: false);
    if (all.isEmpty) return 0;

    bool overlaps(int a0, int a1, int b0, int b1) {
      final s = a0 > b0 ? a0 : b0;
      final e = a1 < b1 ? a1 : b1;
      return e > s;
    }

    bool matches(Map<String, dynamic> br) {
      final preferredDays = (br['preferredDays'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final rangesRaw = (br['preferredTimeRanges'] as List?) ?? const [];
      final exactSlots = (br['exactSlots'] as List?) ?? const [];

      // 1) exactSlots: si hay un slot exacto dentro del hueco
      for (final x in exactSlots) {
        if (x is! Timestamp) continue;
        final dt = x.toDate();
        if (BookingRequestUtils.yyyymmdd(dt) != dayKey) continue;
        if ((dt.isAfter(freedStart) || dt.isAtSameMomentAs(freedStart)) &&
            dt.isBefore(freedEnd)) {
          return true;
        }
      }

      // 2) preferredDay + ranges
      if (!preferredDays.contains(dayKey)) return false;

      // si no puso rangos, pero sí día -> match ("cualquier hora")
      if (rangesRaw.isEmpty) return true;

      for (final r in rangesRaw) {
        if (r is! Map) continue;
        final rs = (r['start'] is num)
            ? (r['start'] as num).toInt()
            : int.tryParse('${r['start'] ?? ''}') ?? -1;
        final re = (r['end'] is num)
            ? (r['end'] as num).toInt()
            : int.tryParse('${r['end'] ?? ''}') ?? -1;
        if (rs < 0 || re < 0) continue;
        if (overlaps(startMin, endMin, rs, re)) return true;
      }

      return false;
    }

    final matched = <Map<String, dynamic>>[];
    for (final d in all) {
      final br = d.data();
      if (matches(br)) {
        matched.add({
          'requestId': d.id,
          'clientId': (br['clientId'] ?? '').toString(),
          'notes': (br['notes'] ?? '').toString(),
        });
      }
    }

    if (matched.isEmpty) return 0;

    // Evita spam: 1 sola notificación resumen (con top 12)
    final top = matched.take(12).toList(growable: false);
    final title = 'Freed slot matches booking requests';
    final hh = freedStart.hour.toString().padLeft(2, '0');
    final mm = freedStart.minute.toString().padLeft(2, '0');
    final body =
        'A slot became available on $dayKey ($hh:$mm for ${freedDurationMin}m). Matches: ${matched.length}.';

    await _safeAddAlert({
      'type': 'freed_slot_matches',
      'title': title,
      'body': body,
      'reason': reason,
      'workerId': workerId,
      'sourceAppointmentId': sourceAppointmentId,
      'slot': {
        'day': dayKey,
        'start': Timestamp.fromDate(freedStart),
        'durationMin': freedDurationMin,
      },
      'matches': top,
      'matchesCount': matched.length,
    });

    return matched.length;
  }

  /// ✅ Borra requests expiradas (si ya pasó la última fecha posible)
  Future<int> pruneExpiredActiveRequests({String? clientId}) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    Query<Map<String, dynamic>> q = _req.where('active', isEqualTo: true);
    if (clientId != null && clientId.trim().isNotEmpty) {
      q = q.where('clientId', isEqualTo: clientId.trim());
    }

    final snap = await q.get();
    if (snap.docs.isEmpty) return 0;

    final batch = db.batch();
    final affectedClients = <String>{};
    int deleted = 0;

    for (final d in snap.docs) {
      final data = d.data();
      final latest = _latestPossibleDateTime(data);
      if (latest == null) continue;

      if (latest.isBefore(todayStart)) {
        deleted++;
        batch.delete(d.reference);
        final cid = (data['clientId'] ?? '').toString();
        if (cid.isNotEmpty) affectedClients.add(cid);
      }
    }

    if (deleted == 0) return 0;
    await batch.commit();

    // marcadores para futura alerta en Home
    final nowTs = FieldValue.serverTimestamp();
    for (final cid in affectedClients) {
      final rest = await _req
          .where('clientId', isEqualTo: cid)
          .where('active', isEqualTo: true)
          .get();

      await _clientRef(cid).set({
        'bookingRequestActive': rest.docs.isNotEmpty,
        'bookingRequestUpdatedAt': nowTs,
        'bookingRequestExpiredAt': nowTs,
        'bookingRequestExpiredAlert': true,
        'updatedAt': nowTs,
      }, SetOptions(merge: true));

      // ✅ notificación (1 por cliente afectado)
      await _safeAddAlert({
        'type': 'booking_request_expired_deleted',
        'clientId': cid,
        'title': 'Expired booking request deleted',
        'body': 'One or more booking requests were automatically deleted because they expired.',
      });
    }

    return deleted;
  }

  DateTime? _latestPossibleDateTime(Map<String, dynamic> br) {
    DateTime? latest;

    final days = (br['preferredDays'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    for (final s in days) {
      final d = BookingRequestUtils.parseYyyymmdd(s);
      if (d == null) continue;
      latest = (latest == null || d.isAfter(latest)) ? d : latest;
    }

    final slots = (br['exactSlots'] as List?) ?? const [];
    for (final x in slots) {
      if (x is Timestamp) {
        final dt = x.toDate();
        latest = (latest == null || dt.isAfter(latest)) ? dt : latest;
      }
    }

    return latest;
  }
}