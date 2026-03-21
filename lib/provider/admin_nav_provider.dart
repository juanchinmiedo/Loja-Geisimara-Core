import 'package:flutter/foundation.dart';

/// Payload that tells BookingAdminScreen to jump to a specific appointment
/// and open the appropriate dialog once the week view is shown.
class PendingAppointmentOpen {
  const PendingAppointmentOpen({
    required this.appointmentId,
    required this.data,
    required this.appointmentDate,
    required this.isPast,
  });

  final String appointmentId;
  final Map<String, dynamic> data;
  final DateTime appointmentDate;
  final bool isPast;
}

class AdminNavProvider extends ChangeNotifier {
  int tabIndex = 0; // 0=Home, 1=Clients, 2=Booking, 3=Profile
  String? openClientId; // para abrir detalle al entrar en Clients
  String? bookingClientId;

  /// Set when the user taps an appointment card in ClientProfileScreen.
  /// BookingAdminScreen consumes this once it appears on screen.
  PendingAppointmentOpen? pendingAppointmentOpen;

  void goToClientsAndOpen(String clientId) {
    tabIndex = 1;
    openClientId = clientId;
    notifyListeners();
  }

  void goToBookingWithClient(String clientId) {
    tabIndex = 2;
    bookingClientId = clientId;
    notifyListeners();
  }

  /// Navigate to the Booking tab (week view) and open the edit/past dialog
  /// for [appointmentId] once the screen is ready.
  void goToBookingAndOpenAppointment({
    required String appointmentId,
    required Map<String, dynamic> data,
    required DateTime appointmentDate,
    required bool isPast,
  }) {
    pendingAppointmentOpen = PendingAppointmentOpen(
      appointmentId: appointmentId,
      data: data,
      appointmentDate: appointmentDate,
      isPast: isPast,
    );
    tabIndex = 2;
    notifyListeners();
  }

  /// Called by BookingAdminScreen after it has consumed the pending open.
  void clearPendingAppointmentOpen() {
    if (pendingAppointmentOpen == null) return;
    pendingAppointmentOpen = null;
    notifyListeners();
  }

  void clearOpenClient() {
    openClientId = null;
    notifyListeners();
  }

  void setTab(int i) {
    tabIndex = i;
    notifyListeners();
  }
}
