import 'package:flutter/material.dart';
import '../services/storage_service.dart';

/// Açık / Koyu tema durum yönetimi
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await StorageService.getThemeMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await StorageService.saveThemeMode(_isDarkMode);
  }
}
