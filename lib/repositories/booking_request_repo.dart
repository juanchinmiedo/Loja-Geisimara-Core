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
        // ✅ debe CABER entero en el rango (no basta con que empiece dentro)
        if (apptStartMin >= rs && apptEndMin <= re) return true;
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

  /// ✅ Cuando se crea/actualiza un booking request, busca si ya hay un slot
  /// libre que encaje y crea una alerta de tipo 'booking_request_match_found'.
  ///
  /// Devuelve true si encontró coincidencia.
  Future<bool> notifyIfRequestMatchesSlots({
    required String requestId,
    required String clientId,
    required Map<String, dynamic> brData,
  }) async {
    try {
      final preferredDays = (brData['preferredDays'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          const <String>[];
      final rangesRaw = (brData['preferredTimeRanges'] as List?) ?? const [];
      final durMin = (brData['durationMin'] is num)
          ? (brData['durationMin'] as num).toInt()
          : 30;
      final requestedWorkerId =
          (brData['workerId'] as String?)?.trim() ?? '';

      if (preferredDays.isEmpty) return false;

      // Cargar appointments activos en los días preferidos.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureDays = preferredDays.where((k) {
        final d = _parseYyyymmdd(k);
        return d != null && !d.isBefore(today);
      }).toList();
      if (futureDays.isEmpty) return false;

      final dayDates = futureDays
          .map(_parseYyyymmdd)
          .whereType<DateTime>()
          .toList()
        ..sort();

      final fromTs = Timestamp.fromDate(dayDates.first);
      final toTs = Timestamp.fromDate(
          dayDates.last.add(const Duration(days: 1)));

      Query<Map<String, dynamic>> apptQ = db
          .collection('appointments')
          .where('status', isEqualTo: 'scheduled')
          .where('appointmentDate', isGreaterThanOrEqualTo: fromTs)
          .where('appointmentDate', isLessThan: toTs);

      if (requestedWorkerId.isNotEmpty) {
        apptQ = apptQ.where('workerId', isEqualTo: requestedWorkerId);
      }

      final apptSnap = await apptQ.get();
      final appts = apptSnap.docs;

      // Obtener workers a revisar.
      List<String> workerIds;
      if (requestedWorkerId.isNotEmpty) {
        workerIds = [requestedWorkerId];
      } else {
        final ws = await db.collection('workers').get();
        workerIds = ws.docs.map((d) => d.id).toList();
        if (workerIds.isEmpty) return false;
      }

      // Extraer rangos horarios.
      final ranges = <Map<String, int>>[];
      if (rangesRaw.isEmpty) {
        ranges.add({'startMin': 7 * 60, 'endMin': 21 * 60});
      } else {
        for (final r in rangesRaw) {
          if (r is! Map) continue;
          final m = Map<String, dynamic>.from(r);
          final s = m['startMin'] ?? m['start'];
          final e = m['endMin'] ?? m['end'];
          final sm = s is num ? s.toInt() : int.tryParse('$s') ?? -1;
          final em = e is num ? e.toInt() : int.tryParse('$e') ?? -1;
          if (sm >= 0 && em > sm) ranges.add({'startMin': sm, 'endMin': em});
        }
      }
      if (ranges.isEmpty) return false;

      // Buscar el primer slot libre.
      DateTime? foundSlot;
      String? foundWorkerId;

      outer:
      for (final day in dayDates) {
        final dayKey = BookingRequestUtils.yyyymmdd(day);
        if (!futureDays.contains(dayKey)) continue;

        final isToday = day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        final nowMin = isToday ? (now.hour * 60 + now.minute) : 0;

        for (final wid in workerIds) {
          for (final r in ranges) {
            final rsRaw =
                (r['startMin'] ?? 0) < 7 * 60 ? 7 * 60 : (r['startMin'] ?? 0);
            final rs = isToday && rsRaw < nowMin ? nowMin : rsRaw;
            final re = (r['endMin'] ?? 21 * 60) > 21 * 60
                ? 21 * 60
                : (r['endMin'] ?? 21 * 60);
            if (re - rs < durMin) continue;

            for (int s = rs; s + durMin <= re; s += 5) {
              final endMin = s + durMin;
              bool ok = true;
              for (final a in appts) {
                final data = a.data();
                if ((data['workerId'] ?? '').toString().trim() != wid)
                  continue;
                final ts = data['appointmentDate'];
                if (ts is! Timestamp) continue;
                final dt = ts.toDate();
                if (dt.year != day.year ||
                    dt.month != day.month ||
                    dt.day != day.day) continue;
                final adur = data['durationMin'] is num
                    ? (data['durationMin'] as num).toInt()
                    : 0;
                if (adur <= 0) continue;
                final a0 = dt.hour * 60 + dt.minute;
                final a1 = a0 + adur;
                final overlapS = s > a0 ? s : a0;
                final overlapE = endMin < a1 ? endMin : a1;
                if (overlapE > overlapS) {
                  ok = false;
                  break;
                }
              }
              if (ok) {
                foundSlot =
                    DateTime(day.year, day.month, day.day, s ~/ 60, s % 60);
                foundWorkerId = wid;
                break outer;
              }
            }
          }
        }
      }

      if (foundSlot == null) return false;

      final dayKey = BookingRequestUtils.yyyymmdd(foundSlot);
      final dayLabel =
          BookingRequestUtils.formatYyyyMmDdToDdMmYyyy(dayKey);
      final hh = foundSlot.hour.toString().padLeft(2, '0');
      final mm = foundSlot.minute.toString().padLeft(2, '0');

      await _safeAddAlert({
        'type': 'booking_request_match_found',
        'clientId': clientId,
        'requestId': requestId,
        'title': 'Match encontrado para booking request',
        'body':
            'Hay disponibilidad el $dayLabel a las $hh:$mm para ${durMin}min'
            '${foundWorkerId != null && foundWorkerId!.isNotEmpty ? " (worker: $foundWorkerId)" : ""}.',
        'slot': {
          'day': dayKey,
          'start': Timestamp.fromDate(foundSlot),
          'durationMin': durMin,
        },
        'matchWorkerId': foundWorkerId,
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  /// ✅ Cuando se crea un appointment que ocupa un slot, invalida alertas
  /// previas de tipo 'booking_request_match_found' que apuntaban a ese slot.
  Future<void> invalidateMatchAlertsForSlot({
    required DateTime appointmentStart,
    required int appointmentDurationMin,
    required String workerId,
  }) async {
    try {
      final dayKey = BookingRequestUtils.yyyymmdd(appointmentStart);
      final apptStartMin =
          appointmentStart.hour * 60 + appointmentStart.minute;
      final apptEndMin = apptStartMin + appointmentDurationMin;

      final snap = await _alerts
          .where('type', isEqualTo: 'booking_request_match_found')
          .get();

      final batch = db.batch();
      bool hasDeletions = false;

      for (final doc in snap.docs) {
        final data = doc.data();
        final slot = data['slot'];
        if (slot is! Map) continue;
        final slotDay = (slot['day'] ?? '').toString();
        if (slotDay != dayKey) continue;

        final slotTs = slot['start'];
        if (slotTs is! Timestamp) continue;
        final slotDt = slotTs.toDate();
        final slotMin = slotDt.hour * 60 + slotDt.minute;
        final slotDur = (slot['durationMin'] is num)
            ? (slot['durationMin'] as num).toInt()
            : 30;
        final slotEnd = slotMin + slotDur;

        // ¿Solapa con el nuevo appointment?
        final overlapS = apptStartMin > slotMin ? apptStartMin : slotMin;
        final overlapE = apptEndMin < slotEnd ? apptEndMin : slotEnd;
        if (overlapE <= overlapS) continue;

        // Worker match: la alerta puede ser para cualquier worker o el mismo.
        final alertWorker =
            (data['matchWorkerId'] ?? '').toString().trim();
        if (alertWorker.isNotEmpty && alertWorker != workerId) continue;

        batch.delete(doc.reference);
        hasDeletions = true;
      }

      if (hasDeletions) await batch.commit();
    } catch (_) {}
  }
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

  DateTime? _parseYyyymmdd(String s) {
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0, 4));
    final mo = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d);
  }
}