import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_app/utils/booking_request_utils.dart';

class BookingRequestRepo {
  BookingRequestRepo(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _req =>
      db.collection('booking_requests');

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