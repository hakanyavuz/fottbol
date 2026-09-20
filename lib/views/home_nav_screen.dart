import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'team_selection_screen.dart';
import 'smart_coupons_screen.dart';
import 'live_matches_screen.dart';
import 'settings_screen.dart';

import 'value_bet_radar_screen.dart';

/// Ana Alt Navigasyon Çubuğu Ekranı
class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeamSelectionScreen(),
    ValueBetRadarScreen(),
    SmartCouponsScreen(),
    LiveMatchesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer, color: AppColors.primary),
            label: 'Tahmin',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar, color: Colors.greenAccent),
            label: 'Radar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome, color: Colors.amber),
            label: 'Kuponlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors, color: Colors.redAccent),
            label: 'Canlı',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: AppColors.primary),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
