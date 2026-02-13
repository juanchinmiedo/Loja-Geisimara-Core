import 'package:firebase_auth/firebase_auth.dart';

class RoleHelper {
  static Future<List<String>> getMyRoles({bool forceRefresh = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // ✅ forceRefresh=true para que pille claims recién puestos
    final token = await user.getIdTokenResult(forceRefresh);
    final claims = token.claims ?? {};

    final raw = claims['roles'];
    if (raw is List) {
      return raw.whereType<String>().map((e) => e.toLowerCase().trim()).toList();
    }

    return [];
  }

  /// Compat con el viejo "role" string (devuelve el primero si quieres).
  /// Pero tu app ya debería usar roles() / isAdmin / isWorker.
  static Future<String?> getMyRole() async {
    final roles = await getMyRoles();
    if (roles.isEmpty) return null;

    // preferimos admin si existe
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('worker')) return 'worker';
    return roles.first;
  }

  /// Viejo método: admin o staff
  /// Ahora: admin o worker
  static Future<bool> isAdminOrStaff() async {
    final roles = await getMyRoles();
    return roles.contains('admin') || roles.contains('worker');
  }

  static Future<bool> isAdmin() async {
    final roles = await getMyRoles();
    return roles.contains('admin');
  }

  /// staff antiguo -> worker nuevo
  static Future<bool> isStaff() async {
    final roles = await getMyRoles();
    return roles.contains('worker');
  }

  static Future<bool> canUseAdminMode() async {
    // Antes: admin/staff podían
    // Ahora: esto ya debería basarse en claims, así que se queda igual:
    return isAdminOrStaff();
  }
}
