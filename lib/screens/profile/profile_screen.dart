// lib/screens/profile/profile_screen.dart
//
// Cambio: ya no lee 'role' de Firestore.
// Muestra roles reales desde UserProvider (Custom Claims).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salon_app/widgets/language_pill.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/screens/introduction/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final user =
          await Authentication.signInWithGoogle(context: context);
      if (user == null) return;

      if (!mounted) return;
      final userProvider = context.read<UserProvider>();
      userProvider.setUser(user);
      await userProvider.refreshSessionWithRetry();

      if (!mounted) return;
      context.read<AdminNavProvider>().setTab(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      context.read<UserProvider>().setUser(null);
      context.read<AdminNavProvider>().setTab(0);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<UserProvider>().user ??
        FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
      Scaffold(
      appBar: AppBar(
        title:
            const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purple))
          : user == null
              ? _buildLoggedOutView()
              : _buildLoggedInView(context, user),
    ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 18,
        child: const LanguagePill(),
      ),
    ]);
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                size: 80, color: Color(0xff721c80)),
            const SizedBox(height: 16),
            Text(
              'Sign in to manage your appointments',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff721c80),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Continue with Google',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    // Lee roles y workerId desde UserProvider (Custom Claims) — no Firestore
    final userProvider = context.watch<UserProvider>();
    final rolesText = userProvider.roles.isEmpty
        ? 'No roles assigned'
        : userProvider.roles.join(', ');
    final workerId = userProvider.workerId ?? '—';
    final accessType = userProvider.isWorkerAdmin
        ? 'Admin + Worker'
        : userProvider.isAdmin
            ? 'Admin'
            : userProvider.isWorker
                ? 'Worker'
                : 'No access';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName ?? 'User',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (user.email != null) ...[
            const SizedBox(height: 4),
            Text(user.email!,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // ── Info desde claims (no Firestore) ──────────────────────────
          _infoRow(Icons.verified_user_outlined, 'Access', accessType,
              const Color(0xff721c80)),
          const SizedBox(height: 8),
          _infoRow(Icons.badge_outlined, 'Roles', rolesText, Colors.grey),
          const SizedBox(height: 8),
          _infoRow(
              Icons.work_outline, 'Worker ID', workerId, Colors.grey),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign out',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
