// lib/services/availability_service.dart
//
// Refactor(commit 10): extracted from clients_profile_screen.dart
//
// Centraliza toda la lógica de cálculo de disponibilidad de slots
// para booking requests. Antes estaba copiada en clients_profile_screen
// (y previamente en home_client_bottom_sheet).
//
// Uso:
//   final svc = AvailabilityService();
//   final result = svc.availabilityFor(br: br, appts: appts);
//   final label  = svc.pillLabel(result.status, result.nextStart);
//   final stream = svc.apptStreamForRequests(brList);

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:salon_app/utils/booking_request_utils.dart';
import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/widgets/booking_request_card.dart';

class AvailabilityService {
  // Business hours
  static const int bizStartMin = 7 * 60;
  static const int bizEndMax   = 21 * 60;
  static const int stepMin     = 5;

  // ── Public API ────────────────────────────────────────────────────────────────

  /// Computes availability for one booking request given loaded appointments.
  /// Fixed worker: synchronous slot scan.
  /// Any worker: returns `unknown` — caller handles async via FutureBuilder.
  ({BookingRequestAvailability status, DateTime? nextStart}) availabilityFor({
    required Map<String, dynamic> br,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    final workerIdRaw = (br['workerId'] ?? '').toString().trim();
    if (workerIdRaw.isEmpty) {
      return (status: BookingRequestAvailability.unknown, nextStart: null);
    }

    final preferredDays = (br['preferredDays'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ?? const <String>[];

    final ranges  = extractRanges(br);
    final durMin  = requestedDurationMin(br);
    final allowed = allowedOverlapMin(durMin);

    // No preferred days → scan next 30 days from today
    final today = startOfDay(DateTime.now());
    final daysToScan = preferredDays.isEmpty
        ? List.generate(30, (i) => today.add(Duration(days: i)))
        : (preferredDays
            .map((k) => BookingRequestUtils.parseYyyymmdd(k))
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => a.compareTo(b)));

    for (final day in daysToScan) {
      final first = firstSlotOnDay(
        day: day, ranges: ranges, durMin: durMin,
        workerId: workerIdRaw, allowedOverlap: allowed, appts: appts,
      );
      if (first != null) {
        return (status: BookingRequestAvailability.available, nextStart: first);
      }
    }
    return (status: BookingRequestAvailability.unavailable, nextStart: null);
  }

  /// Computes availability across ALL workers (for "any worker" requests).
  ({BookingRequestAvailability status, DateTime? nextStart}) availabilityForAnyWorker({
    required Map<String, dynamic> br,
    required List<String> workerIds,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    if (workerIds.isEmpty) {
      return (status: BookingRequestAvailability.unknown, nextStart: null);
    }

    final preferredDays = (br['preferredDays'] as List?)
            ?.map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList() ?? const <String>[];

    final ranges  = extractRanges(br);
    final durMin  = requestedDurationMin(br);
    final allowed = allowedOverlapMin(durMin);

    final today = startOfDay(DateTime.now());
    final daysToScan = preferredDays.isEmpty
        ? List.generate(30, (i) => today.add(Duration(days: i)))
        : (preferredDays
            .map((k) => BookingRequestUtils.parseYyyymmdd(k))
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => a.compareTo(b)));

    DateTime? best;
    for (final day in daysToScan) {
      for (final wid in workerIds) {
        final first = firstSlotOnDay(
          day: day, ranges: ranges, durMin: durMin,
          workerId: wid, allowedOverlap: allowed, appts: appts,
        );
        if (first != null && (best == null || first.isBefore(best))) {
          best = first;
        }
      }
      if (best != null) break;
    }

    return best != null
        ? (status: BookingRequestAvailability.available,  nextStart: best)
        : (status: BookingRequestAvailability.unavailable, nextStart: null);
  }

  /// Formats the availability result into a pill label string.
  String pillLabel(BookingRequestAvailability status, DateTime? nextStart) {
    if (status == BookingRequestAvailability.unknown) return 'Checking…';
    if (status == BookingRequestAvailability.unavailable) return 'No availability';
    if (nextStart == null) return ' ';
    final hm   = DateTimeUtils.hhmmFromMinutes(
        nextStart.hour * 60 + nextStart.minute);
    final ddmm = '${nextStart.day.toString().padLeft(2, '0')}/'
                 '${nextStart.month.toString().padLeft(2, '0')}';
    return '$hm · $ddmm';
  }

  /// Returns a Firestore stream covering all appointment dates needed to
  /// evaluate availability for a list of booking requests.
  Stream<QuerySnapshot<Map<String, dynamic>>>? apptStreamForRequests(
    List<Map<String, dynamic>> brList,
  ) {
    DateTime? minDay, maxDay;
    for (final br in brList) {
      final days = (br['preferredDays'] as List?)
              ?.map((e) => e.toString()).toList() ?? const <String>[];
      for (final k in days) {
        final dt = BookingRequestUtils.parseYyyymmdd(k);
        if (dt == null) continue;
        if (minDay == null || dt.isBefore(minDay)) minDay = dt;
        if (maxDay == null || dt.isAfter(maxDay)) maxDay = dt;
      }
    }
    // No preferred days → stream next 30 days
    final today = startOfDay(DateTime.now());
    final from  = minDay ?? today;
    final to    = maxDay ?? today.add(const Duration(days: 30));
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay(from)))
        .where('appointmentDate',
            isLessThan: Timestamp.fromDate(endExclusive(to)))
        .snapshots();
  }

  // ── Helpers (accessible for callers that need them) ───────────────────────────

  int requestedDurationMin(Map<String, dynamic> br) {
    final v = br['durationMin'];
    if (v is num) return v.toInt();
    return 30;
  }

  int allowedOverlapMin(int durMin) => durMin > 60 ? 15 : 0;

  int overlapMin(int a0, int a1, int b0, int b1) {
    final s = a0 > b0 ? a0 : b0;
    final e = a1 < b1 ? a1 : b1;
    return e > s ? e - s : 0;
  }

  bool slotOkForWorker({
    required DateTime day,
    required int startMin,
    required int durMin,
    required String workerId,
    required int allowedOverlap,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    final endMin = startMin + durMin;
    for (final a in appts) {
      final data = a.data();
      if ((data['status'] ?? '').toString() != 'scheduled') continue;
      if ((data['workerId'] ?? '').toString().trim() != workerId) continue;
      final ts = data['appointmentDate'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();
      if (dt.year != day.year || dt.month != day.month || dt.day != day.day) continue;
      final adur = data['durationMin'] is num
          ? (data['durationMin'] as num).toInt() : 0;
      if (adur <= 0) continue;
      final a0 = dt.hour * 60 + dt.minute;
      if (overlapMin(startMin, endMin, a0, a0 + adur) > allowedOverlap) return false;
    }
    return true;
  }

  DateTime? firstSlotOnDay({
    required DateTime day,
    required List<Map<String, int>> ranges,
    required int durMin,
    required String workerId,
    required int allowedOverlap,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> appts,
  }) {
    for (final r in ranges) {
      final rs = ((r['startMin'] ?? 0) < bizStartMin
          ? bizStartMin : (r['startMin'] ?? 0));
      final re = ((r['endMin'] ?? 24 * 60) > bizEndMax
          ? bizEndMax : (r['endMin'] ?? 24 * 60));
      if (re - rs < durMin) continue;
      for (int s = rs; s + durMin <= re; s += stepMin) {
        if (slotOkForWorker(
          day: day, startMin: s, durMin: durMin,
          workerId: workerId, allowedOverlap: allowedOverlap, appts: appts,
        )) {
          return DateTime(day.year, day.month, day.day, s ~/ 60, s % 60);
        }
      }
    }
    return null;
  }

  List<Map<String, int>> extractRanges(Map<String, dynamic> br) {
    final raw = (br['preferredTimeRanges'] as List?) ?? const [];
    if (raw.isEmpty) return const [{'startMin': 0, 'endMin': 24 * 60}];
    final out = <Map<String, int>>[];
    for (final r in raw) {
      if (r is! Map) continue;
      final m  = Map<String, dynamic>.from(r);
      final s  = m['startMin'] ?? m['start'];
      final e  = m['endMin']   ?? m['end'];
      final sm = s is num ? s.toInt() : int.tryParse('$s') ?? -1;
      final em = e is num ? e.toInt() : int.tryParse('$e') ?? -1;
      if (sm >= 0 && em > sm) out.add({'startMin': sm, 'endMin': em});
    }
    return out.isEmpty ? const [{'startMin': 0, 'endMin': 24 * 60}] : out;
  }

  DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime endExclusive(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));
}
