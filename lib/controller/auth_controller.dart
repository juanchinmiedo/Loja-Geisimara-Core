// lib/controller/auth_controller.dart
//
// Cambio vs versión anterior:
//   _ensureUserDoc() ya NO escribe 'role: user'.
//   Firestore users/{uid} es solo perfil — los permisos viven en Custom Claims.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {
  // ── Sign in ────────────────────────────────────────────────────────────────

  static Future<User?> signInWithGoogle({required BuildContext context}) async {
    final auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      try {
        final credential = await auth.signInWithPopup(GoogleAuthProvider());
        user = credential.user;
        if (user != null) await _ensureUserDoc(user);
        return user;
      } catch (e) {
        debugPrint('Google sign-in (web) failed: $e');
        return null;
      }
    }

    try {
      final g = GoogleSignIn();
      await g.signOut(); // limpia tokens caducados

      GoogleSignInAccount? googleUser = await g.signInSilently();
      googleUser ??= await g.signIn();
      if (googleUser == null) return null; // usuario canceló

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        debugPrint('idToken null. Revisa provider Google en Firebase.');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await auth.signInWithCredential(credential);
      user = result.user;
      if (user != null) await _ensureUserDoc(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException code=${e.code} msg=${e.message}');
    } catch (e) {
      debugPrint('Unexpected error during Google sign-in: $e');
    }

    return user;
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error during sign-out: $e');
    }
  }

  // ── Firestore profile doc ──────────────────────────────────────────────────
  //
  // Solo guarda datos de perfil (nombre, email, foto, timestamps).
  // NO escribe 'role' — los permisos viven exclusivamente en Custom Claims.
  // workerId se mantiene si ya existe (lo escribe el admin manualmente
  // o el script de setup).
  //
  static Future<void> _ensureUserDoc(User user) async {
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'name': user.displayName,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        // workerId NO se escribe aquí — se añade manualmente o por script
      });
    } else {
      // Solo actualiza perfil, NO toca workerId ni ningún campo de permisos
      await ref.update({
        'email': user.email,
        'name': user.displayName,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
