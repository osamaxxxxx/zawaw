import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark == null) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isDarkMode');
  }
}
