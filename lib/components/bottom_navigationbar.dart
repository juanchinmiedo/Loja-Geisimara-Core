import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/generated/l10n.dart';

import 'package:salon_app/provider/admin_mode_provider.dart';
import 'package:salon_app/provider/admin_nav_provider.dart';

import 'package:salon_app/screens/booking/booking_screen.dart';
import 'package:salon_app/screens/booking/booking_admin.dart';

import 'package:salon_app/screens/home/home_screen.dart';
import 'package:salon_app/screens/home/home_admin_screen.dart';

import 'package:salon_app/screens/maps/maps_screen.dart';
import 'package:salon_app/screens/clients/clients_admin_screen.dart';

import 'package:salon_app/screens/profile/profile_screen.dart';

class BottomNavigationComponent extends StatelessWidget {
  const BottomNavigationComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isAdminMode = context.watch<AdminModeProvider>().enabled;
    final nav = context.watch<AdminNavProvider>();
    final bookingClientId = context.watch<AdminNavProvider>().bookingClientId;

    final screens = isAdminMode
        ? [
            const HomeAdminScreen(),          // 0
            const ClientsAdminScreen(),       // 1
            BookingAdminScreen(preselectedClientId: bookingClientId),       // 2  (ver mini-cambio abajo para preselected)
            const ProfileScreen(),            // 3
          ]
        : [
            HomeScreen(onBookNow: () => context.read<AdminNavProvider>().setTab(2)), // 0
            const MapsPage(),                 // 1
            const BookingScreen(),            // 2
            const ProfileScreen(),            // 3
          ];

    final items = isAdminMode
        ? [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, color: Color(0xff721c80)),
              label: s.homeTab,
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xff721c80)),
              label: s.clientsTab, // ya lo tienes
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
          ]
        : [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, color: Color(0xff721c80)),
              label: s.homeTab,
              backgroundColor: Colors.white,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_on_outlined, color: Color(0xff721c80)),
              label: s.mapsTab,
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

    return Scaffold(
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
    );
  }
}
