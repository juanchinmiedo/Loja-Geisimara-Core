import 'package:flutter/foundation.dart';

class AdminNavProvider extends ChangeNotifier {
  int tabIndex = 0; // 0=Home, 1=Clients, 2=Booking, 3=Profile
  String? openClientId; // para abrir detalle al entrar en Clients
  String? bookingClientId;

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

  void clearOpenClient() {
    openClientId = null;
    notifyListeners();
  }

  void setTab(int i) {
    tabIndex = i;
    notifyListeners();
  }
}
