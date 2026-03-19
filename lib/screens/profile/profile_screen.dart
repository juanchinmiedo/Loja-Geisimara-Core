// lib/screens/profile/profile_screen.dart
//
// Cambio: ya no lee 'role' de Firestore.
// Muestra roles reales desde UserProvider (Custom Claims).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/widgets/language_pill.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/screens/introduction/onboarding_screen.dart';
import 'package:salon_app/utils/localization_helper.dart';

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
    final s = S.of(context);
    final user =
        context.watch<UserProvider>().user ??
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileTab, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: LanguagePill())],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purple))
          : user == null
              ? _buildLoggedOutView()
              : _buildLoggedInView(context, user),
    );
  }

  Widget _buildLoggedOutView() {
    final s = S.of(context);
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
              s.signInToManage,
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
              label: Text(s.continueWithGoogle, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    final s = S.of(context);
    // Lee roles y workerId desde UserProvider (Custom Claims) — no Firestore
    final userProvider = context.watch<UserProvider>();
    final rolesText = userProvider.roles.isEmpty
        ? s.noRolesAssigned
        : userProvider.roles.join(', ');
    final workerId = userProvider.workerId ?? '—';
    final accessType = userProvider.isWorkerAdmin
        ? s.adminWorkerRole
        : userProvider.isAdmin
            ? s.adminRole
            : userProvider.isWorker
                ? s.workerRole
                : s.noAccess;

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
            user.displayName ?? s.userRole,
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
          _infoRow(Icons.verified_user_outlined, s.access, accessType,
              const Color(0xff721c80)),
          const SizedBox(height: 8),
          _infoRow(Icons.badge_outlined, s.roles, rolesText, Colors.grey),
          const SizedBox(height: 8),
          _infoRow(
              Icons.work_outline, s.workerId, workerId, Colors.grey),

          // ── Worker stats ─────────────────────────────────────────────
          if (userProvider.isWorker && workerId != '—')
            _buildWorkerStats(workerId),

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
            label: Text(s.logout, style: const TextStyle(color: Colors.white, fontSize: 16)),
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

  // ── Worker stats section ──────────────────────────────────────────────────────
  Widget _buildWorkerStats(String workerId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadWorkerStats(workerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: Color(0xff721c80))),
          );
        }
        final stats = snap.data!;
        final total      = stats['total'] as int;
        final revenue    = stats['revenue'] as double;
        final byService  = stats['byService'] as Map<String, int>;

        final s = S.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xff721c80), size: 20),
                const SizedBox(width: 8),
                Text(s.myStats, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            // Summary row
            Row(
              children: [
                _statChip(Icons.check_circle_outline, '$total', s.procedures, Colors.green),
                const SizedBox(width: 10),
                _statChip(Icons.euro_rounded, revenue.toStringAsFixed(0), s.revenue, const Color(0xff721c80)),
              ],
            ),
            if (byService.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(s.byProcedure, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              ...(byService.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                  .map((e) => _serviceRow(context, e.key, e.value)),
            ],
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadWorkerStats(String workerId) async {
    final snap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('workerId', isEqualTo: workerId)
        .where('status', whereIn: ['done', 'scheduled'])
        .get();

    final now = DateTime.now();
    int total = 0;
    double revenue = 0;
    final byService = <String, int>{};

    for (final doc in snap.docs) {
      final data   = doc.data();
      final status = (data['status'] ?? '').toString();
      final ts     = data['appointmentDate'];
      final isPast = ts is Timestamp && ts.toDate().isBefore(now);

      // Count only done or past-scheduled (attended)
      if (status == 'done' || (status == 'scheduled' && isPast)) {
        total++;
        // Revenue: finalPrice > total > basePrice
        final fp  = data['finalPrice'];
        final tot = data['total'];
        final bp  = data['basePrice'];
        final price = (fp is num)  ? fp.toDouble()
                    : (tot is num) ? tot.toDouble()
                    : (bp  is num) ? bp.toDouble()
                    : 0.0;
        revenue += price;

        // Service label
        final svcKey   = (data['serviceNameKey']   ?? '').toString().trim();
        final svcLabel = (data['serviceName']       ?? '').toString().trim();
        final key = svcKey.isNotEmpty ? svcKey : (svcLabel.isNotEmpty ? svcLabel : '—');
        byService[key] = (byService[key] ?? 0) + 1;
      }
    }

    return {'total': total, 'revenue': revenue, 'byService': byService};
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceRow(BuildContext context, String svcKey, int count) {
    // Translate service key if possible
    final label = svcKey.length < 20 && !svcKey.contains(' ')
        ? _trySvcKey(context, svcKey)
        : svcKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xff721c80).withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xff721c80))),
          ),
        ],
      ),
    );
  }

  String _trySvcKey(BuildContext context, String key) {
    try {
      return trServiceOrAddon(context, key);
    } catch (_) {
      return key;
    }
  }

}
