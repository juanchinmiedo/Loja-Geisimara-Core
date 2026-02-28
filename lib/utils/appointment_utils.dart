import 'package:salon_app/utils/date_time_utils.dart';
import 'package:salon_app/utils/string_utils.dart';

class AppointmentUtils {
  static String dayKey(DateTime d) {
    return DateTimeUtils.yyyymmdd(d);
  }

  static String slug(String s) {
    return StringUtils.slug(s);
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
