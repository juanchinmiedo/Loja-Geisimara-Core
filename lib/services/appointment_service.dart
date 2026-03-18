// lib/services/appointment_service.dart
//
// FIX: renaming stats bucket
//
// PROBLEMA: al crear un appointment con status='scheduled', se incrementaba
// stats.totalScheduled. Eso hacía que en la pantalla de stats apareciera
// "Attended: N" contando también appointments futuros (scheduled), cuando
// "Attended" debería ser solo los que ya ocurrieron (status='done').
//
// SOLUCIÓN:
//  • status='scheduled' → incrementa stats.totalScheduled  (appointments pendientes)
//  • status='done'      → incrementa stats.totalDone       (realmente asistidos)
//  • El campo que se muestra como "Attended" en UI pasa a leer totalDone.
//  • Los appointments futuros (scheduled) no aparecen en Attended.
//  • Al pasar de scheduled → done, totalScheduled-- y totalDone++  (ya manejado
//    por setStatus con _cap('done') = 'totalDone')
//
// MIGRACIÓN: los docs de clients existentes tienen stats.totalScheduled
// mezclando futuros + pasados asistidos. No hay migración automática —
// los contadores se recalcularán solos a medida que los appointments
// cambien de status. Para un recálculo limpio, ver fix_stats Cloud Function.

import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  AppointmentService(this._db);
  final FirebaseFirestore _db;

  // Valid statuses
  static const _validStatuses = {'scheduled', 'done', 'cancelled', 'noShow'};

  String _norm(String v) {
    final s = v.trim();
    return _validStatuses.contains(s) ? s : 'scheduled';
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Create ────────────────────────────────────────────────────────────────────

  /// Call right after creating a new appointment.
  /// - stats.totalAppointments++
  /// - stats.total<initialStatus>++ (scheduled by default)
  /// - lastAppointmentAt / lastAppointmentSummary only if status = done
  ///   (future appointments don't count as "last attended")
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
      final statsUpdate = <String, dynamic>{
        'totalAppointments': FieldValue.increment(1),
        'total${_cap(initialStatus)}': FieldValue.increment(1),
      };

      // Only update lastAppointmentAt for DONE appointments (already attended).
      // Scheduled (future) appointments must NOT count as "last attended".
      if (initialStatus == 'done') {
        if (appointmentDate != null) {
          statsUpdate['lastAppointmentAt'] =
              Timestamp.fromDate(appointmentDate);
        }
        if (lastSummary != null) {
          statsUpdate['lastAppointmentSummary'] = lastSummary;
        }
      }

      tx.set(
        clientRef,
        {
          'stats': statsUpdate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // ── Change status ─────────────────────────────────────────────────────────────

  /// Changes status and adjusts counters:
  ///   total<oldStatus>--
  ///   total<newStatus>++
  /// Also updates lastAppointmentAt when transitioning TO 'done'.
  Future<void> setStatus({
    required String appointmentId,
    required String clientId,
    required String newStatus,
  }) async {
    newStatus = _norm(newStatus);

    final apptRef   = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      final apptSnap = await tx.get(apptRef);
      if (!apptSnap.exists) return;

      final appt      = apptSnap.data() as Map<String, dynamic>;
      final oldStatus = _norm((appt['status'] ?? 'scheduled').toString());

      if (oldStatus == newStatus) {
        tx.update(apptRef, {'updatedAt': FieldValue.serverTimestamp()});
        return;
      }

      tx.update(apptRef, {
        'status':    newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final statsUpdate = <String, dynamic>{
        'total${_cap(oldStatus)}': FieldValue.increment(-1),
        'total${_cap(newStatus)}': FieldValue.increment(1),
      };

      // When marking as done → update last attended appointment info
      if (newStatus == 'done') {
        final ts = appt['appointmentDate'];
        if (ts is Timestamp) {
          statsUpdate['lastAppointmentAt'] = ts;
        }
        final svc = (appt['serviceName'] ?? appt['serviceNameLabel'] ?? '').toString();
        if (svc.isNotEmpty) {
          statsUpdate['lastAppointmentSummary'] = svc;
        }
      }

      tx.set(
        clientRef,
        {
          'stats': statsUpdate,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // ── Delete ────────────────────────────────────────────────────────────────────

  /// Hard delete by mistake:
  ///   totalAppointments--
  ///   total<currentStatus>--
  Future<void> deletePermanent({
    required String appointmentId,
    required String clientId,
  }) async {
    final apptRef   = _db.collection('appointments').doc(appointmentId);
    final clientRef = _db.collection('clients').doc(clientId);

    await _db.runTransaction((tx) async {
      final apptSnap = await tx.get(apptRef);
      if (!apptSnap.exists) return;

      final appt   = apptSnap.data() as Map<String, dynamic>;
      final status = _norm((appt['status'] ?? 'scheduled').toString());

      tx.delete(apptRef);

      tx.set(
        clientRef,
        {
          'stats': {
            'totalAppointments':       FieldValue.increment(-1),
            'total${_cap(status)}':    FieldValue.increment(-1),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // ── Convenience wrappers ──────────────────────────────────────────────────────

  Future<void> cancelAppointment({
    required String appointmentId,
    required String clientId,
  }) => setStatus(
      appointmentId: appointmentId,
      clientId: clientId,
      newStatus: 'cancelled');

  Future<void> noShowAppointment({
    required String appointmentId,
    required String clientId,
  }) => setStatus(
      appointmentId: appointmentId,
      clientId: clientId,
      newStatus: 'noShow');

  Future<void> markDone({
    required String appointmentId,
    required String clientId,
  }) => setStatus(
      appointmentId: appointmentId,
      clientId: clientId,
      newStatus: 'done');

  Future<void> markScheduled({
    required String appointmentId,
    required String clientId,
  }) => setStatus(
      appointmentId: appointmentId,
      clientId: clientId,
      newStatus: 'scheduled');
}
