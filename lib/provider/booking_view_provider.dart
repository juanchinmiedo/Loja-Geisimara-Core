import 'package:flutter/material.dart';

enum BookingViewMode { day, week }

class BookingViewProvider extends ChangeNotifier {
  BookingViewMode _mode = BookingViewMode.day;

  BookingViewMode get mode => _mode;
  bool get isDay => _mode == BookingViewMode.day;
  bool get isWeek => _mode == BookingViewMode.week;

  void toggle() {
    _mode = _mode == BookingViewMode.day ? BookingViewMode.week : BookingViewMode.day;
    notifyListeners();
  }

  void setMode(BookingViewMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
  }
}
