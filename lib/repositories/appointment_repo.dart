import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentRepo {
  AppointmentRepo(this._db);
  final FirebaseFirestore _db;

  Future<void> createAppointment({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String serviceId,
    required String serviceName,
    required String dayKey,
    required int startMin,
    required int endMin,
  }) async {
    final appointmentRef =
        _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      tx.set(appointmentRef, {
        'clientId': clientId,
        'clientName': clientName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'date': dayKey,
        'startMin': startMin,
        'endMin': endMin,
        'status': 'done', // ✅ default
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        clientRef,
        {
          'stats.totalAppointments': FieldValue.increment(1),
          'stats.lastAppointmentAt': FieldValue.serverTimestamp(),
          'stats.lastAppointmentSummary': serviceName,
        },
        SetOptions(merge: true),
      );
    });
  }
  Future<void> cancelAppointment({
    required String appointmentId,
    required String clientId,
  }) async {
    final apptRef = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      tx.update(apptRef, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        clientRef,
        {
          'stats.totalCancelled': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> noShowAppointment({
    required String appointmentId,
    required String clientId,
  }) async {
    final apptRef = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      tx.update(apptRef, {
        'status': 'noShow',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        clientRef,
        {
          'stats.totalNoShow': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    });
  }
}
