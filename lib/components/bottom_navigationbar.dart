import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/screens/booking/booking_admin.dart';
import 'package:salon_app/screens/home/home_admin_screen.dart';
import 'package:salon_app/screens/clients/clients_admin_screen.dart';
import 'package:salon_app/screens/profile/profile_screen.dart';

class BottomNavigationComponent extends StatefulWidget {
  const BottomNavigationComponent({super.key});

  @override
  State<BottomNavigationComponent> createState() => _BottomNavigationComponentState();
}

class _BottomNavigationComponentState extends State<BottomNavigationComponent> {
  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    final nav = context.read<AdminNavProvider>();

    // Si no estamos en Home, volver a Home en lugar de salir
    if (nav.tabIndex != 0) {
      nav.setTab(0);
      return false;
    }

    // Estamos en Home — doble tap en menos de 2 segundos para salir
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(milliseconds: 800)) {
      _lastBackPress = now;
      return false;
    }

    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s   = S.of(context);
    final nav = context.watch<AdminNavProvider>();
    final bookingClientId = nav.bookingClientId;

    final screens = [
      const HomeAdminScreen(),
      const ClientsAdminScreen(),
      BookingAdminScreen(preselectedClientId: bookingClientId),
      const ProfileScreen(),
    ];

    final items = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home, color: Color(0xff721c80)),
        label: s.homeTab,
        backgroundColor: Colors.white,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xff721c80)),
        label: s.clientsTab,
        backgroundColor: Colors.white,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.edit_calendar_outlined, color: Color(0xff721c80)),
        label: s.bookingTab,
        backgroundColor: Colors.white,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person, color: Color(0xff721c80)),
        label: s.profileTab,
        backgroundColor: Colors.white,
      ),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: screens[nav.tabIndex.clamp(0, screens.length - 1)],
        bottomNavigationBar: BottomNavigationBar(
          items: items,
          type: BottomNavigationBarType.shifting,
          currentIndex: nav.tabIndex.clamp(0, items.length - 1),
          selectedItemColor: Colors.black,
          iconSize: 26,
          onTap: (i) => context.read<AdminNavProvider>().setTab(i),
          elevation: 5,
        ),
      ),
    );
  }
}
