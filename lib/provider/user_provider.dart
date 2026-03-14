// lib/provider/user_provider.dart
//
// Fuente única de verdad para autenticación y permisos.
//
// Reglas del sistema:
//   • Custom Claims mandan — Firestore es solo perfil/espejo.
//   • worker puro   → selectedWorkerId = su workerId (bloqueado)
//   • admin puro    → selectedWorkerId = null (ALL)
//   • admin+worker  → selectedWorkerId = su workerId (preseleccionado, puede cambiar)
//
// workerId se lee primero de claims, luego de Firestore como fallback.
// refreshSessionWithRetry() resuelve el delay de propagación de claims.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  List<String> _roles = const [];
  List<String> get roles => _roles;

  String? _workerId;
  String? get workerId => _workerId;

  /// null = ALL (solo cuando isAdmin y no hay worker propio seleccionado)
  String? _selectedWorkerId;
  String? get selectedWorkerId => _selectedWorkerId;

  bool _setupMissingForWorker = false;
  bool get setupMissingForWorker => _setupMissingForWorker;

  bool get isAdmin => _roles.contains('admin');
  bool get isWorker => _roles.contains('worker');
  bool get isWorkerAdmin => isAdmin && isWorker;

  /// True si tiene al menos un role válido → puede usar la app
  bool get isAuthorized => isAdmin || isWorker;

  // ── Auth stream ────────────────────────────────────────────────────────────
  //
  // SOLO reacciona al sign-out.
  // El login lo manejan OnBoardingScreen y SplashScreen de forma explícita
  // con refreshSessionWithRetry(), garantizando que los claims estén listos
  // antes de navegar.
  //
  void bindAuthStream() {
    _auth.authStateChanges().listen((u) {
      if (u != null) {
        // Login detectado por el stream — solo guardamos referencia.
        // No llamamos refreshSession aquí: el token puede no tener claims aún.
        if (_user == null || _user!.uid != u.uid) {
          _user = u;
          notifyListeners();
        }
        return;
      }
      // Sign-out → reset completo
      _resetState();
    });
  }

  void _resetState() {
    _user = null;
    _roles = const [];
    _workerId = null;
    _selectedWorkerId = null;
    _setupMissingForWorker = false;
    notifyListeners();
  }

  // ── Session refresh ────────────────────────────────────────────────────────

  Future<void> refreshSession() async {
    // Usa siempre el usuario activo de FirebaseAuth, no el guardado en memoria,
    // para evitar referencias obsoletas tras un reload().
    await _auth.currentUser?.reload();
    final u = _auth.currentUser;

    if (u == null) {
      _resetState();
      return;
    }

    _user = u;

    // Force-refresh: garantiza que obtenemos los claims más recientes
    final token = await u.getIdTokenResult(true);
    final claims = token.claims ?? {};

    // ── Roles ──────────────────────────────────────────────────────────────
    final rawRoles = claims['roles'];
    final parsedRoles = <String>[];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          final n = r.toLowerCase().trim();
          if (n.isNotEmpty && !parsedRoles.contains(n)) parsedRoles.add(n);
        }
      }
    }
    _roles = parsedRoles;

    // ── workerId: claims primero, Firestore como fallback ─────────────────
    final claimWorkerId =
        (claims['workerId'] as String?)?.trim();
    String? resolvedWorkerId =
        (claimWorkerId != null && claimWorkerId.isNotEmpty)
            ? claimWorkerId
            : null;

    if (resolvedWorkerId == null) {
      // Fallback: leer de Firestore users/{uid}
      final snap = await _db.collection('users').doc(u.uid).get();
      final data = snap.data() ?? {};
      final fsWorkerId = (data['workerId'] as String?)?.trim();
      resolvedWorkerId =
          (fsWorkerId != null && fsWorkerId.isNotEmpty) ? fsWorkerId : null;
    }

    _workerId = resolvedWorkerId;

    // ── selectedWorkerId según rol ─────────────────────────────────────────
    if (!isAuthorized) {
      _selectedWorkerId = null;
      _setupMissingForWorker = false;
    } else if (isAdmin) {
      // admin puro → ALL; admin+worker → su propio worker preseleccionado
      _selectedWorkerId =
          (isWorker && _workerId != null) ? _workerId : null;
      _setupMissingForWorker = false;
    } else {
      // worker puro → siempre bloqueado a su workerId
      _selectedWorkerId = _workerId;
      _setupMissingForWorker = (_workerId == null);
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('[UserProvider] uid=${u.uid} '
          'roles=$_roles workerId=$_workerId '
          'selected=$_selectedWorkerId authorized=$isAuthorized');
    }

    notifyListeners();
  }

  // ── Retry para claims con propagación tardía ───────────────────────────────
  //
  // Firebase propaga custom claims con un pequeño delay (~1-3s).
  // Si el primer refreshSession() devuelve roles vacíos, reintentamos
  // hasta [attempts] veces antes de dar acceso denegado.
  //
  Future<void> refreshSessionWithRetry({
    int attempts = 5,
    Duration delay = const Duration(milliseconds: 1500),
  }) async {
    for (int i = 0; i < attempts; i++) {
      await refreshSession();
      if (isAuthorized) return;
      if (i < attempts - 1) await Future.delayed(delay);
    }
    // Si llegamos aquí con isAuthorized=false → acceso denegado legítimo
  }

  // ── Filtro de worker (solo admin puede cambiar) ────────────────────────────

  void setWorkerFilter(String? workerId) {
    if (!isAdmin) return;
    _selectedWorkerId = workerId;
    notifyListeners();
  }

  // ── Helpers para queries y creación ───────────────────────────────────────

  /// workerId para filtrar queries de Firestore.
  /// Admin con ALL → null (sin filtro, ve todo).
  /// Worker puro   → su workerId siempre.
  String? workerIdForQueries() {
    if (_user == null || !isAuthorized) return null;
    if (isAdmin) return _selectedWorkerId; // null = ALL
    return _workerId;
  }

  /// workerId para crear un nuevo appointment.
  String workerIdForCreate() {
    if (_user == null || !isAuthorized) throw Exception('Not authorized');
    if (!isAdmin) {
      if (_workerId == null) throw Exception('Worker missing workerId');
      return _workerId!;
    }
    if (_selectedWorkerId == null || _selectedWorkerId!.isEmpty) {
      throw Exception('Select a worker first');
    }
    return _selectedWorkerId!;
  }

  // ── Compat ─────────────────────────────────────────────────────────────────

  void setUser(User? newUser) {
    _user = newUser;
    if (newUser == null) {
      _resetState();
      return;
    }
    notifyListeners();
  }

  User? getUser() => _user;
}
