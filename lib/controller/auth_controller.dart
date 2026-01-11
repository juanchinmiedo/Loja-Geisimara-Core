import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {
  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    final auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      try {
        final credential = await auth.signInWithPopup(GoogleAuthProvider());
        user = credential.user;

        if (user != null) {
          await _ensureUserDoc(user);
        }

        return user;
      } catch (e) {
        debugPrint('Google sign-in (web) failed: $e');
        return null;
      }
    }

    try {
      // 1) Cierra sesión previa para evitar tokens caducados/mezclados.
      final g = GoogleSignIn();
      await g.signOut();

      // 2) Intenta silencioso primero (si ya hay cuenta elegida).
      GoogleSignInAccount? googleUser = await g.signInSilently();
      googleUser ??= await g.signIn(); // 3) Si no, muestra selector de cuenta.

      if (googleUser == null) {
        // Usuario canceló
        return null;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        // Si llegara a ser null, normalmente es porque falta default_web_client_id
        // o el proveedor Google no está activado en Firebase Auth.
        debugPrint(
          'idToken es null. Revisa provider Google en Firebase y default_web_client_id.',
        );
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await auth.signInWithCredential(credential);
      user = result.user;

      if (user != null) {
        await _ensureUserDoc(user);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code=${e.code} message=${e.message}');
      // e.code comunes: 'invalid-credential', 'user-disabled', etc.
    } catch (e) {
      debugPrint('Unexpected error during Google sign-in: $e');
    }

    return user;
  }

  /// Crea/actualiza users/{uid} para que tus rules (hasRole/role) funcionen.
  /// - Si no existe: crea con role "user"
  /// - Si existe: actualiza name/email/foto sin tocar role
  static Future<void> _ensureUserDoc(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final payloadCreate = <String, dynamic>{
      'email': user.email,
      'name': user.displayName,
      'photoURL': user.photoURL,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    final payloadUpdate = <String, dynamic>{
      'email': user.email,
      'name': user.displayName,
      'photoURL': user.photoURL,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(payloadCreate);
    } else {
      // Importante: no tocamos role aquí para no pisar admin/staff
      await ref.update(payloadUpdate);
    }
  }
}
