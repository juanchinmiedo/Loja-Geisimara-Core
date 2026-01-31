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

  /// Admin filter: null = ALL workers
  String? _selectedWorkerId;
  String? get selectedWorkerId => _selectedWorkerId;

  bool _setupMissingForWorker = false;
  bool get setupMissingForWorker => _setupMissingForWorker;

  bool get isAdmin => _roles.contains("admin");
  bool get isWorker => _roles.contains("worker");
  bool get isWorkerAdmin => isAdmin && isWorker;

  /// Call once at app start
  void bindAuthStream() {
    _auth.authStateChanges().listen((u) async {
      _user = u;
      _roles = const [];
      _workerId = null;
      _selectedWorkerId = null;
      _setupMissingForWorker = false;
      notifyListeners();

      if (u == null) return;
      await refreshSession();
    });
  }

  Future<void> refreshSession() async {
    final u = _user;
    if (u == null) return;

    // ✅ Force refresh so new claims apply
    final token = await u.getIdTokenResult(true);
    final claims = token.claims ?? {};

    final rawRoles = claims["roles"];
    final roles = <String>[];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) roles.add(r);
      }
    }
    _roles = roles;

    // Load Firestore users/{uid}
    final snap = await _db.collection("users").doc(u.uid).get();
    final data = snap.data() ?? {};
    _workerId = data["workerId"]?.toString();

    _setupMissingForWorker =
        (isWorker && !isAdmin && (_workerId == null || _workerId!.isEmpty));

    if (isAdmin) {
      // Admin: if also worker -> default to own workerId, else ALL
      _selectedWorkerId = (isWorker && _workerId != null && _workerId!.isNotEmpty)
          ? _workerId
          : null;
    } else {
      // Worker: force to own
      _selectedWorkerId = _workerId;
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print("[UserProvider] uid=${u.uid} roles=$_roles workerId=$_workerId selected=$_selectedWorkerId");
    }

    notifyListeners();
  }

  void setWorkerFilter(String? workerId) {
    if (!isAdmin) return;
    _selectedWorkerId = workerId;
    notifyListeners();
  }

  String? workerIdForQueries() {
    if (_user == null) return null;
    if (isAdmin) return _selectedWorkerId; // null = ALL
    return _workerId;
  }

  String workerIdForCreate() {
    if (_user == null) throw Exception("Not logged in");

    if (!isAdmin) {
      if (_workerId == null || _workerId!.isEmpty) {
        throw Exception("Worker missing workerId in Firestore users/{uid}");
      }
      return _workerId!;
    }

    if (_selectedWorkerId == null || _selectedWorkerId!.isEmpty) {
      throw Exception("Select a worker first (cannot create in All workers view)");
    }
    return _selectedWorkerId!;
  }

  // Compatibility with old code
  void setUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }

  User? getUser() => _user;
}
