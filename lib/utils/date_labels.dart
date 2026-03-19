import 'package:salon_app/generated/l10n.dart';

// Original hardcoded (kept for backward compat — not used for display anymore)
String months(int m) {
  const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  if (m < 1 || m > 12) return '';
  return names[m - 1];
}
String week(int weekday) {
  const names = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
  if (weekday < 1 || weekday > 7) return '';
  return names[weekday - 1];
}

// Localized versions — use these in UI
String monthsL10n(int m, S s) {
  switch (m) {
    case 1:  return s.monthJan;
    case 2:  return s.monthFeb;
    case 3:  return s.monthMar;
    case 4:  return s.monthApr;
    case 5:  return s.monthMay;
    case 6:  return s.monthJun;
    case 7:  return s.monthJul;
    case 8:  return s.monthAug;
    case 9:  return s.monthSep;
    case 10: return s.monthOct;
    case 11: return s.monthNov;
    case 12: return s.monthDec;
    default: return '';
  }
}

String weekL10n(int weekday, S s) {
  switch (weekday) {
    case 1: return s.weekdayMon;
    case 2: return s.weekdayTue;
    case 3: return s.weekdayWed;
    case 4: return s.weekdayThu;
    case 5: return s.weekdayFri;
    case 6: return s.weekdaySat;
    case 7: return s.weekdaySun;
    default: return '';
  }
}
