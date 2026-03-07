import 'package:flutter/material.dart';
import 'dart:ui';
import 'dashboard_kms_screen.dart';
import 'dashboard_bumil_screen.dart';
import 'dashboard_kader_screen.dart';
import 'history_screen.dart';
import 'info_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String role; // 'orang_tua', 'ibu_hamil', 'kader'
  const MainNavigation({super.key, this.role = 'orang_tua'});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    switch (role) {
      case 'ibu_hamil':
        _pages = [
          const DashboardBumilScreen(),
          HistoryScreen(role: role),
          InfoScreen(role: role),
          ProfileScreen(role: role),
        ];
        break;
      case 'kader':
        _pages = [
          const DashboardKaderScreen(),
          HistoryScreen(role: role),
          InfoScreen(role: role),
          ProfileScreen(role: role),
        ];
        break;
      default: // orang_tua
        _pages = [
          const DashboardKmsScreen(),
          HistoryScreen(role: role),
          InfoScreen(role: role),
          ProfileScreen(role: role),
        ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to go behind the floating nav bar
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 40.0, right: 40.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(
                    0.3,
                  ), // Light grey translucent (simulating frosted glass)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded),
                    _buildNavItem(1, Icons.history_rounded),
                    _buildNavItem(2, Icons.article_rounded),
                    _buildNavItem(3, Icons.person_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
            : null,
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF4FC3F7) : Colors.white70,
          size: 26,
        ),
      ),
    );
  }
}
