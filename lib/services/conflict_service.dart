import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConflictService {
  ConflictService(this._db);

  final FirebaseFirestore _db;

  int minutesOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final start = aStart.isAfter(bStart) ? aStart : bStart;
    final end = aEnd.isBefore(bEnd) ? aEnd : bEnd;
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Future<int> maxOverlapForCandidate({
    required DateTime day,
    required DateTime candidateStart,
    required int candidateDurationMin,
    required String workerId, // ✅ ahora ES POR WORKER
    String? excludeAppointmentId,
  }) async {
    final dayStart = Timestamp.fromDate(DateTime(day.year, day.month, day.day));
    final dayEnd = Timestamp.fromDate(DateTime(day.year, day.month, day.day, 23, 59, 59, 999));

    // ✅ Importantísimo: conflicto solo contra citas del mismo worker
    final snap = await _db
        .collection('appointments')
        .where('status', isEqualTo: 'scheduled')
        .where('workerId', isEqualTo: workerId)
        .where('appointmentDate', isGreaterThanOrEqualTo: dayStart)
        .where('appointmentDate', isLessThanOrEqualTo: dayEnd)
        .orderBy('appointmentDate')
        .get();

    final candidateEnd = candidateStart.add(
      Duration(minutes: candidateDurationMin <= 0 ? 0 : candidateDurationMin),
    );

    int maxOverlap = 0;

    for (final doc in snap.docs) {
      if (excludeAppointmentId != null && doc.id == excludeAppointmentId) continue;

      final data = doc.data();
      final ts = data['appointmentDate'];
      if (ts is! Timestamp) continue;

      final start = ts.toDate();
      final dur = (data['durationMin'] is num) ? (data['durationMin'] as num).toInt() : 0;
      final end = start.add(Duration(minutes: dur <= 0 ? 0 : dur));

      final overlap = minutesOverlap(candidateStart, candidateEnd, start, end);
      if (overlap > maxOverlap) maxOverlap = overlap;
    }

    return maxOverlap;
  }

  Future<bool> confirmSaveIfConflict({
    required BuildContext context,
    required int maxOverlapMin,
    int amberThresholdMin = 30,
  }) async {
    if (maxOverlapMin <= 0) return true;

    final isSevere = maxOverlapMin >= amberThresholdMin;
    final color = isSevere ? Colors.red : Colors.amber;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Time conflict"),
        content: Text(
          "This appointment overlaps another by $maxOverlapMin min.\n\n"
          "Save anyway or change time?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text("Change time"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(_, true),
            child: const Text("Save anyway", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return res == true;
  }
}
