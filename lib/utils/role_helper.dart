import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleHelper {
  static Future<String?> getMyRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snap.exists) return null;

    final data = snap.data();
    if (data == null) return null;

    final role = data['role'];
    if (role is String && role.isNotEmpty) return role.toLowerCase().trim();

    return null;
  }

  static Future<bool> isAdminOrStaff() async {
    final role = await getMyRole();
    return role == 'admin' || role == 'staff';
  }

  static Future<bool> isAdmin() async {
    final role = await getMyRole();
    return role == 'admin';
  }

  static Future<bool> isStaff() async {
    final role = await getMyRole();
    return role == 'staff';
  }

  static Future<bool> canUseAdminMode() async {
    return isAdminOrStaff();
  }
}
