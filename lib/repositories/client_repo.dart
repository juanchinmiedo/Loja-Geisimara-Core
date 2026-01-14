import 'package:cloud_firestore/cloud_firestore.dart';

class ClientRepo {
  ClientRepo(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> clientRef(String clientId) =>
      _db.collection('clients').doc(clientId);

  Future<Map<String, dynamic>> getClient(String clientId) async {
    final snap = await clientRef(clientId).get();
    return snap.data() ?? {};
  }

  Future<void> setBookingRequest({
    required String clientId,
    required bool active,
    required String notes,
  }) async {
    final ref = clientRef(clientId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final existingBR = (data?['bookingRequest'] as Map<String, dynamic>?) ?? {};
      final existingCreatedAt = existingBR['createdAt'];

      tx.set(
        ref,
        {
          'bookingRequest': {
            'active': active,
            'notes': notes.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
            if (existingCreatedAt == null) 'createdAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> updateClientData({
    required String clientId,
    required String firstName,
    required String lastName,
    required int country,
    required int phone,
    required String instagram,
  }) async {
    await clientRef(clientId).set(
      {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'country': country,
        'phone': phone,
        'instagram': instagram.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteClient(String clientId) async {
    await clientRef(clientId).delete();
  }
}
