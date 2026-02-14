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