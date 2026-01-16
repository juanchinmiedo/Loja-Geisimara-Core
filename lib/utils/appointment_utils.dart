class AppointmentUtils {
  static String dayKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y$m$day";
  }

  static String slug(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  static String buildAppointmentId({
    required DateTime date,
    required String firstName,
    required String lastName,
    required String serviceName,
  }) {
    final day = dayKey(date);
    return "${day}_${slug(firstName)}_${slug(lastName)}_${slug(serviceName)}";
  }
}
