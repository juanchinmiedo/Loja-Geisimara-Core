import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/provider/admin_mode_provider.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/controller/auth_controller.dart';
import 'package:salon_app/utils/role_helper.dart';

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

      final user = await Authentication.signInWithGoogle(context: context);

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        context.read<UserProvider>().setUser(user);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
      context.read<AdminModeProvider>().reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user ?? FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff721c80),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : user == null
              ? _buildLoggedOutView(context)
              : _buildLoggedInView(context, user),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Color(0xff721c80)),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Continue with Google',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, User user) {
    final adminMode = context.watch<AdminModeProvider>().enabled;

    final userDocStream =
        FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: userDocStream,
      builder: (context, snap) {
        final role = (snap.data?.data() as Map<String, dynamic>?)?['role'] as String?;
        final roleText = (role ?? '').toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? 'User',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              if (user.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.email!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 6),
              if (role != null)
                Text(
                  'Role: $roleText',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your appointments (coming soon)',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),

              const SizedBox(height: 24),

              FutureBuilder<bool>(
                future: RoleHelper.canUseAdminMode(),
                builder: (context, snap) {
                  final canAdmin = snap.data == true;
                  if (!canAdmin) return const SizedBox.shrink();

                  return Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff721c80),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          final provider = context.read<AdminModeProvider>();
                          provider.setEnabled(!provider.enabled);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.enabled ? 'Modo admin activado' : 'Modo usuario activado',
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          adminMode ? Icons.person : Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
                        label: Text(
                          adminMode ? 'Back to user mode' : 'Start admin mode',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
