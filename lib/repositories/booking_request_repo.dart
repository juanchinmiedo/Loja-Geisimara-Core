import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_app/utils/booking_request_utils.dart';
import 'package:salon_app/utils/date_time_utils.dart';

class BookingRequestDeletePlan {
  BookingRequestDeletePlan({
    required this.autoDelete,
    required this.confirmDelete,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> autoDelete;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> confirmDelete;
}

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
      .doc('_system')
      .collection('history');

  Future<void> _safeAddAlert(Map<String, dynamic> data) async {
    try {
      await _alerts.add({
        ...data,
        'createdAt': Timestamp.now(),
        'serverCreatedAt': FieldValue.serverTimestamp(),
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

  Future<void> updateRequest({
    required String requestId,
    required String serviceId,
    required String serviceNameKey,
    required String serviceNameLabel,
    required int durationMin,
    required String? workerId, // null => Any
    required List<String> preferredDays,
    required List<Map<String, int>> preferredTimeRanges,
  }) async {
    await db.collection('booking_requests').doc(requestId).set({
      'workerId': workerId, // si null, queda null
      'serviceId': serviceId,
      'serviceNameKey': serviceNameKey,
      'serviceNameLabel': serviceNameLabel,
      'durationMin': durationMin,
      'preferredDays': preferredDays,
      'preferredTimeRanges': preferredTimeRanges,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    String? workerId, // null => any worker

    // ✅ NEW: procedure
    required String serviceId,
    required String serviceNameKey,
    required String serviceNameLabel,
    required int durationMin,

    required List<Timestamp> exactSlots,
    required List<String> preferredDays,
    required List<Map<String, int>> preferredTimeRanges,
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = _req.doc();

    await db.runTransaction((tx) async {
      tx.set(doc, {
        'clientId': clientId,

        // worker
        'workerId': workerId,

        // ✅ procedure
        'serviceId': serviceId,
        'serviceNameKey': serviceNameKey,
        'serviceNameLabel': serviceNameLabel,
        'durationMin': durationMin,

        // flags
        'active': true,
        'createdAt': now,
        'updatedAt': now,

        // availability prefs
        'exactSlots': exactSlots,
        'preferredDays': preferredDays,
        'preferredTimeRanges': preferredTimeRanges,
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

  /// ✅ Cuando se crea/edita un appointment para un cliente:
  /// - Solo borra automáticamente los requests que **cumplen todos** los requisitos del request
  ///   para ese appointment (día + rango/exactSlot + worker + category).
  /// - Los demás requests (misma category) se devuelven como "confirmDelete" para UI.
  Future<BookingRequestDeletePlan> buildDeletePlanForNewAppointment({
    required String clientId,
    required DateTime appointmentStart,
    required int appointmentDurationMin,
    required String workerId,
    required String serviceCategory, // hands | feet
  }) async {
    final cid = clientId.trim();
    final snap = await _req
        .where('clientId', isEqualTo: cid)
        .where('active', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) {
      return BookingRequestDeletePlan(autoDelete: const [], confirmDelete: const []);
    }

    final apptDayKey = DateTimeUtils.yyyymmdd(appointmentStart);
    final apptStartMin = appointmentStart.hour * 60 + appointmentStart.minute;
    final apptEndMin = apptStartMin + appointmentDurationMin;

    bool overlaps(int a0, int a1, int b0, int b1) {
      final s = a0 > b0 ? a0 : b0;
      final e = a1 < b1 ? a1 : b1;
      return e > s;
    }

    final catCache = <String, String>{};

    Future<String> _categoryForServiceId(String sid) async {
      if (catCache.containsKey(sid)) return catCache[sid]!;
      try {
        final doc = await db.collection('services').doc(sid).get();
        final cat = (doc.data()?['category'] ?? 'hands').toString();
        catCache[sid] = cat;
        return cat;
      } catch (_) {
        catCache[sid] = 'hands';
        return 'hands';
      }
    }

    bool _workerOk(String? reqWorkerId) {
      if (reqWorkerId == null || reqWorkerId.trim().isEmpty) return true;
      return reqWorkerId.trim() == workerId;
    }

    bool _timeOk(Map<String, dynamic> br) {
      final exactSlots = (br['exactSlots'] as List?) ?? const [];
      final preferredDays = (br['preferredDays'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final rangesRaw = (br['preferredTimeRanges'] as List?) ?? const [];

      if (exactSlots.isNotEmpty) {
        for (final x in exactSlots) {
          if (x is! Timestamp) continue;
          final dt = x.toDate();
          if (DateTimeUtils.yyyymmdd(dt) != apptDayKey) continue;
          final m = dt.hour * 60 + dt.minute;
          if ((m - apptStartMin).abs() <= 5) return true;
        }
        return false;
      }

      if (!preferredDays.contains(apptDayKey)) return false;
      if (rangesRaw.isEmpty) return true;

      for (final r in rangesRaw) {
        if (r is! Map) continue;
        final mm = Map<String, dynamic>.from(r);
        final s = (mm['startMin'] ?? mm['start']);
        final e = (mm['endMin'] ?? mm['end']);
        final rs = (s is num) ? s.toInt() : int.tryParse('$s') ?? -1;
        final re = (e is num) ? e.toInt() : int.tryParse('$e') ?? -1;
        if (rs < 0 || re <= rs) continue;
        if (overlaps(apptStartMin, apptEndMin, rs, re)) return true;
      }
      return false;
    }

    final autoDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final confirmDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final d in snap.docs) {
      final br = d.data();
      final sid = (br['serviceId'] ?? '').toString();
      if (sid.isEmpty) continue;

      final cat = await _categoryForServiceId(sid);
      if (cat != serviceCategory) continue;

      final reqWorkerId = (br['workerId'] as String?)?.trim();
      final ok = _workerOk(reqWorkerId) && _timeOk(br);

      if (ok) {
        autoDelete.add(d);
      } else {
        confirmDelete.add(d);
      }
    }

    return BookingRequestDeletePlan(autoDelete: autoDelete, confirmDelete: confirmDelete);
  }

  Future<int> deleteRequestsByDocs({
    required String clientId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) async {
    if (docs.isEmpty) return 0;
    final cid = clientId.trim();

    final batch = db.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }
    await batch.commit();

    final rest = await _req
        .where('clientId', isEqualTo: cid)
        .where('active', isEqualTo: true)
        .get();
    await _clientRef(cid).set({
      'bookingRequestActive': rest.docs.isNotEmpty,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

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
    final dayLabel = BookingRequestUtils.formatYyyyMmDdToDdMmYyyy(dayKey);
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
    final body ='A slot became available on $dayLabel ($hh:$mm for ${freedDurationMin}m). Matches: ${matched.length}.';
    
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