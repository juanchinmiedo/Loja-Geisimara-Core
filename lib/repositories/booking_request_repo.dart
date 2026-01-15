import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRequestRepo {
  BookingRequestRepo(this.db);

  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _req =>
      db.collection('booking_requests');

  DocumentReference<Map<String, dynamic>> _clientRef(String clientId) =>
      db.collection('clients').doc(clientId);

  // --- CLIENT FLAGS ---

  Future<void> setClientLooking(String clientId, bool looking) async {
    await _clientRef(clientId).set({
      'bookingRequestActive': looking,
      'bookingRequestUpdatedAt': FieldValue.serverTimestamp(),
      // opcional: mantiene updatedAt general
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- STREAMS / GETS ---

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamActiveRequestsForClient(String clientId) {
    return _req
        .where('clientId', isEqualTo: clientId)
        .where('active', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getActiveRequestsForClient(String clientId) async {
    final snap = await _req
        .where('clientId', isEqualTo: clientId)
        .where('active', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs;
  }

  // --- UPSERT / UPDATE ---

  Future<void> upsertRequest({
    required String clientId,
    required List<Timestamp> exactSlots,
    required List<String> preferredDays,
    required List<Map<String, int>> preferredTimeRanges,
    required String notes,
  }) async {
    final now = FieldValue.serverTimestamp();

    // Creamos siempre una request nueva (tú querías múltiples).
    final doc = _req.doc();

    await db.runTransaction((tx) async {
      tx.set(doc, {
        'clientId': clientId,
        'active': true,
        'createdAt': now,
        'updatedAt': now,
        'exactSlots': exactSlots,
        'preferredDays': preferredDays,
        'preferredTimeRanges': preferredTimeRanges,
        'notes': notes,
      });

      // ✅ flags en client para Home Admin
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

  // --- DELETE / DISABLE ---

  Future<void> deleteRequest(String requestId) async {
    final now = FieldValue.serverTimestamp();
    final ref = _req.doc(requestId);

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final clientId = (data?['clientId'] ?? '').toString();

      tx.delete(ref);

      // Si no quedan activas, desactivamos el flag
      if (clientId.isNotEmpty) {
        final rest = await _req
            .where('clientId', isEqualTo: clientId)
            .where('active', isEqualTo: true)
            .get();

        if (rest.docs.isEmpty) {
          tx.set(_clientRef(clientId), {
            'bookingRequestActive': false,
            'bookingRequestUpdatedAt': now,
            'updatedAt': now,
          }, SetOptions(merge: true));
        } else {
          tx.set(_clientRef(clientId), {
            'bookingRequestUpdatedAt': now,
            'updatedAt': now,
          }, SetOptions(merge: true));
        }
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

  Future<void> disableAndClearRequests(String clientId) async {
    final now = FieldValue.serverTimestamp();

    // 1) borramos todas activas
    final docs = await getActiveRequestsForClient(clientId);
    final batch = db.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }

    // 2) bajamos flag
    batch.set(_clientRef(clientId), {
      'bookingRequestActive': false,
      'bookingRequestUpdatedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
