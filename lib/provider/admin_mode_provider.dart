import 'package:flutter/material.dart';

class AdminModeProvider extends ChangeNotifier {
  bool _enabled = false;

  bool get enabled => _enabled;

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void toggle() {
    _enabled = !_enabled;
    notifyListeners();
  }

  void reset() {
    _enabled = false;
    notifyListeners();
  }
}
