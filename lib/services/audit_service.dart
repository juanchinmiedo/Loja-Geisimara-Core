// lib/services/audit_service.dart
//
// Servicio de auditoría. Escribe eventos en la colección `audit_log`.
// Se llama desde los dialogs/screens después de cada operación exitosa.
//
// Estructura de cada documento:
//   action:          string  — tipo de acción (ver AuditAction)
//   entityId:        string  — id del documento afectado
//   entityType:      string  — "appointment" | "client" | "booking_request"
//   performedBy:     string  — uid de Firebase Auth
//   performedByName: string  — displayName del user (snapshot)
//   workerId:        string? — workerId si es worker, null si es admin/owner
//   details:         map     — datos relevantes del momento de la acción
//   createdAt:       Timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Tipos de acción ───────────────────────────────────────────────────────────

enum AuditAction {
  // Appointments
  appointmentCreated,
  appointmentEdited,
  appointmentDeleted,
  appointmentStatusChanged,
  appointmentFinalPriceSet,
  appointmentFinalPriceEdited,
  appointmentFinalPriceCleared,

  // Clients
  clientCreated,
  clientEdited,
  clientDeleted,

  // Booking requests
  bookingRequestCreated,
  bookingRequestEdited,
  bookingRequestDeleted,
}

extension AuditActionX on AuditAction {
  String get value {
    switch (this) {
      case AuditAction.appointmentCreated:          return 'appointment_created';
      case AuditAction.appointmentEdited:           return 'appointment_edited';
      case AuditAction.appointmentDeleted:          return 'appointment_deleted';
      case AuditAction.appointmentStatusChanged:    return 'appointment_status_changed';
      case AuditAction.appointmentFinalPriceSet:    return 'appointment_final_price_set';
      case AuditAction.appointmentFinalPriceEdited: return 'appointment_final_price_edited';
      case AuditAction.appointmentFinalPriceCleared:return 'appointment_final_price_cleared';
      case AuditAction.clientCreated:               return 'client_created';
      case AuditAction.clientEdited:                return 'client_edited';
      case AuditAction.clientDeleted:               return 'client_deleted';
      case AuditAction.bookingRequestCreated:       return 'booking_request_created';
      case AuditAction.bookingRequestEdited:        return 'booking_request_edited';
      case AuditAction.bookingRequestDeleted:       return 'booking_request_deleted';
    }
  }

  String get entityType {
    switch (this) {
      case AuditAction.appointmentCreated:
      case AuditAction.appointmentEdited:
      case AuditAction.appointmentDeleted:
      case AuditAction.appointmentStatusChanged:
      case AuditAction.appointmentFinalPriceSet:
      case AuditAction.appointmentFinalPriceEdited:
      case AuditAction.appointmentFinalPriceCleared:
        return 'appointment';
      case AuditAction.clientCreated:
      case AuditAction.clientEdited:
      case AuditAction.clientDeleted:
        return 'client';
      case AuditAction.bookingRequestCreated:
      case AuditAction.bookingRequestEdited:
      case AuditAction.bookingRequestDeleted:
        return 'booking_request';
    }
  }
}

// ── Servicio ──────────────────────────────────────────────────────────────────

class AuditService {
  AuditService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  })  : _db   = db   ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _collection = 'audit_log';

  /// Registra un evento de auditoría.
  ///
  /// [workerId] — si es null se asume que quien actúa es admin/owner.
  /// [details]  — mapa libre con los datos relevantes del momento.
  Future<void> log({
    required AuditAction action,
    required String entityId,
    required Map<String, dynamic> details,
    String? workerId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return; // no logueado → no loguear

      await _db.collection(_collection).add({
        'action':          action.value,
        'entityId':        entityId,
        'entityType':      action.entityType,
        'performedBy':     user.uid,
        'performedByName': user.displayName ?? user.email ?? user.uid,
        'workerId':        workerId,
        'details':         details,
        'createdAt':       FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // El log nunca debe romper el flujo principal
    }
  }

  // ── Helpers de conveniencia ───────────────────────────────────────────────────

  Future<void> logAppointmentCreated({
    required String appointmentId,
    required String clientId,
    required String clientName,
    required String serviceName,
    required String serviceNameKey,
    required DateTime appointmentDate,
    required String workerId,
    required double total,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.appointmentCreated,
    entityId: appointmentId,
    workerId: performerWorkerId,
    details: {
      'clientId':       clientId,
      'clientName':     clientName,
      'serviceName':    serviceName,
      'serviceNameKey': serviceNameKey,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'workerId':       workerId,
      'total':          total,
    },
  );

  Future<void> logAppointmentEdited({
    required String appointmentId,
    required String clientName,
    required String serviceName,
    required DateTime appointmentDate,
    required String workerId,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.appointmentEdited,
    entityId: appointmentId,
    workerId: performerWorkerId,
    details: {
      'clientName':      clientName,
      'serviceName':     serviceName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'workerId':        workerId,
    },
  );

  Future<void> logAppointmentDeleted({
    required String appointmentId,
    required String clientName,
    required String serviceName,
    required String workerId,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.appointmentDeleted,
    entityId: appointmentId,
    workerId: performerWorkerId,
    details: {
      'clientName':  clientName,
      'serviceName': serviceName,
      'workerId':    workerId,
    },
  );

  Future<void> logAppointmentStatusChanged({
    required String appointmentId,
    required String clientName,
    required String oldStatus,
    required String newStatus,
    required String workerId,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.appointmentStatusChanged,
    entityId: appointmentId,
    workerId: performerWorkerId,
    details: {
      'clientName': clientName,
      'oldStatus':  oldStatus,
      'newStatus':  newStatus,
      'workerId':   workerId,
    },
  );

  Future<void> logFinalPrice({
    required String appointmentId,
    required String clientName,
    required String serviceName,
    required num? oldPrice,
    required num? newPrice,
    required String workerId,
    String? performerWorkerId,
  }) {
    final AuditAction action;
    if (oldPrice == null && newPrice != null) {
      action = AuditAction.appointmentFinalPriceSet;
    } else if (newPrice == null) {
      action = AuditAction.appointmentFinalPriceCleared;
    } else {
      action = AuditAction.appointmentFinalPriceEdited;
    }
    return log(
      action:   action,
      entityId: appointmentId,
      workerId: performerWorkerId,
      details: {
        'clientName':  clientName,
        'serviceName': serviceName,
        'oldPrice':    oldPrice,
        'newPrice':    newPrice,
        'workerId':    workerId,
      },
    );
  }

  Future<void> logClientCreated({
    required String clientId,
    required String clientName,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.clientCreated,
    entityId: clientId,
    workerId: performerWorkerId,
    details: {'clientName': clientName},
  );

  Future<void> logClientEdited({
    required String clientId,
    required String clientName,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.clientEdited,
    entityId: clientId,
    workerId: performerWorkerId,
    details: {'clientName': clientName},
  );

  Future<void> logClientDeleted({
    required String clientId,
    required String clientName,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.clientDeleted,
    entityId: clientId,
    workerId: performerWorkerId,
    details: {'clientName': clientName},
  );

  Future<void> logBookingRequestCreated({
    required String requestId,
    required String clientId,
    required String clientName,
    required String serviceNameKey,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.bookingRequestCreated,
    entityId: requestId,
    workerId: performerWorkerId,
    details: {
      'clientId':       clientId,
      'clientName':     clientName,
      'serviceNameKey': serviceNameKey,
    },
  );

  Future<void> logBookingRequestEdited({
    required String requestId,
    required String clientName,
    required String serviceNameKey,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.bookingRequestEdited,
    entityId: requestId,
    workerId: performerWorkerId,
    details: {
      'clientName':     clientName,
      'serviceNameKey': serviceNameKey,
    },
  );

  Future<void> logBookingRequestDeleted({
    required String requestId,
    required String clientName,
    String? performerWorkerId,
  }) => log(
    action:   AuditAction.bookingRequestDeleted,
    entityId: requestId,
    workerId: performerWorkerId,
    details: {'clientName': clientName},
  );
}
