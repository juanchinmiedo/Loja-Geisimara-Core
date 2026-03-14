// lib/repositories/blocked_slot_repo.dart
//
// Gestiona franjas horarias bloqueadas para un worker.
// Colección: workers/{workerId}/blockedSlots/{autoId}
// Doc: { date: '20240620', startMin: 480, endMin: 600, reason: 'Lunch', createdAt }

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedSlot {
  const BlockedSlot({
    required this.id,
    required this.date,
    required this.startMin,
    required this.endMin,
    this.reason = '',
  });

  final String id;
  final String date;     // yyyymmdd
  final int startMin;
  final int endMin;
  final String reason;

  factory BlockedSlot.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return BlockedSlot(
      id:       doc.id,
      date:     (d['date'] ?? '').toString(),
      startMin: (d['startMin'] is num) ? (d['startMin'] as num).toInt() : 0,
      endMin:   (d['endMin']   is num) ? (d['endMin']   as num).toInt() : 0,
      reason:   (d['reason']   ?? '').toString(),
    );
  }
}

class BlockedSlotRepo {
  BlockedSlotRepo(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String workerId) =>
      _db.collection('workers').doc(workerId).collection('blockedSlots');

  // ── Read ─────────────────────────────────────────────────────────────────────

  /// Stream en tiempo real de los slots bloqueados para la semana visible.
  /// [weekDates] son 7 strings yyyymmdd (Lun-Dom).
  Stream<List<BlockedSlot>> streamForWeek(
      String workerId, List<String> weekDates) {
    if (weekDates.isEmpty) return const Stream.empty();
    return _col(workerId)
        .where('date', whereIn: weekDates)
        .snapshots()
        .map((s) => s.docs.map(BlockedSlot.fromDoc).toList());
  }

  /// One-shot para un día concreto.
  Future<List<BlockedSlot>> fetchForDay(
      String workerId, String dateKey) async {
    final snap = await _col(workerId)
        .where('date', isEqualTo: dateKey)
        .get();
    return snap.docs.map(BlockedSlot.fromDoc).toList();
  }

  // ── Write ────────────────────────────────────────────────────────────────────

  Future<String> addSlot({
    required String workerId,
    required String date,
    required int startMin,
    required int endMin,
    String reason = '',
  }) async {
    assert(startMin < endMin, 'startMin must be < endMin');
    final ref = await _col(workerId).add({
      'date':     date,
      'startMin': startMin,
      'endMin':   endMin,
      'reason':   reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteSlot(
      {required String workerId, required String slotId}) async {
    await _col(workerId).doc(slotId).delete();
  }

  Future<void> updateSlot({
    required String workerId,
    required String slotId,
    int? startMin,
    int? endMin,
    String? reason,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (startMin != null) payload['startMin'] = startMin;
    if (endMin   != null) payload['endMin']   = endMin;
    if (reason   != null) payload['reason']   = reason.trim();
    await _col(workerId).doc(slotId).update(payload);
  }

  // ── Conflict helper ──────────────────────────────────────────────────────────

  /// True si [startMin, endMin) se solapa con cualquier bloque del día.
  Future<bool> overlapsBlock({
    required String workerId,
    required String dateKey,
    required int startMin,
    required int endMin,
  }) async {
    final slots = await fetchForDay(workerId, dateKey);
    return slots.any((s) => startMin < s.endMin && endMin > s.startMin);
  }
}
