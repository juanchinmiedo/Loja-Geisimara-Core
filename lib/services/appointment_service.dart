import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  AppointmentService(this._db);
  final FirebaseFirestore _db;

  // scheduled (default), done, cancelled, noShow
  String _norm(String v) {
    final s = v.trim();
    if (s == 'scheduled' || s == 'done' || s == 'cancelled' || s == 'noShow') return s;
    return 'scheduled';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// ✅ Llamar justo después de crear un appointment nuevo.
  /// - stats.totalAppointments++
  /// - stats.totalScheduled++ (si initialStatus == scheduled)
  /// - stats.lastAppointmentAt / lastAppointmentSummary (opcional)
  Future<void> onAppointmentCreated({
    required String appointmentId,
    required String clientId,
    String initialStatus = 'scheduled',
    DateTime? appointmentDate,
    String? lastSummary,
  }) async {
    initialStatus = _norm(initialStatus);

    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      // No necesitas leer el client; tx.set merge crea stats si no existe
      tx.set(
        clientRef,
        {
          'stats': {
            'totalAppointments': FieldValue.increment(1),
            'total${_cap(initialStatus)}': FieldValue.increment(1),
            if (appointmentDate != null) 'lastAppointmentAt': Timestamp.fromDate(appointmentDate),
            if (lastSummary != null) 'lastAppointmentSummary': lastSummary,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// ✅ Cambia status y ajusta buckets correctamente:
  /// - total<oldStatus>--
  /// - total<newStatus>++
  /// (NO toca totalAppointments)
  Future<void> setStatus({
    required String appointmentId,
    required String clientId,
    required String newStatus,
  }) async {
    newStatus = _norm(newStatus);

    final apptRef = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      final apptSnap = await tx.get(apptRef);
      if (!apptSnap.exists) return;

      final appt = apptSnap.data() as Map<String, dynamic>;
      final oldStatus = _norm((appt['status'] ?? 'scheduled').toString());

      if (oldStatus == newStatus) {
        tx.update(apptRef, {'updatedAt': FieldValue.serverTimestamp()});
        return;
      }

      tx.update(apptRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        clientRef,
        {
          'stats': {
            'total${_cap(oldStatus)}': FieldValue.increment(-1),
            'total${_cap(newStatus)}': FieldValue.increment(1),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// ✅ Borrado REAL por error:
  /// - elimina appointment doc
  /// - totalAppointments--
  /// - total<statusActual>--
  Future<void> deletePermanent({
    required String appointmentId,
    required String clientId,
  }) async {
    final apptRef = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      final apptSnap = await tx.get(apptRef);
      if (!apptSnap.exists) return;

      final appt = apptSnap.data() as Map<String, dynamic>;
      final status = _norm((appt['status'] ?? 'scheduled').toString());

      tx.delete(apptRef);

      tx.set(
        clientRef,
        {
          'stats': {
            'totalAppointments': FieldValue.increment(-1),
            'total${_cap(status)}': FieldValue.increment(-1),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // Helpers (nombres cómodos)
  Future<void> cancelAppointment({
    required String appointmentId,
    required String clientId,
  }) =>
      setStatus(appointmentId: appointmentId, clientId: clientId, newStatus: 'cancelled');

  Future<void> noShowAppointment({
    required String appointmentId,
    required String clientId,
  }) =>
      setStatus(appointmentId: appointmentId, clientId: clientId, newStatus: 'noShow');

  Future<void> markDone({
    required String appointmentId,
    required String clientId,
  }) =>
      setStatus(appointmentId: appointmentId, clientId: clientId, newStatus: 'done');

  Future<void> markScheduled({
    required String appointmentId,
    required String clientId,
  }) =>
      setStatus(appointmentId: appointmentId, clientId: clientId, newStatus: 'scheduled');
}
