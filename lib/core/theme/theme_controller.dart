import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light / dark / system choice, saved across launches.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Read the saved choice. Call once before `runApp`; falls back to system
  /// if storage is unavailable.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
  }

  /// Applies immediately; the returned future completes once it's saved
  /// (callers don't need to await it).
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Storage unavailable (e.g. some test / web contexts): keep in-memory only.
    }
  }

  /// Flip between light and dark. When following the system, [current] is
  /// what the user sees right now, so the toggle always visibly changes.
  void toggleTheme([Brightness? current]) {
    final showingDark = _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && current == Brightness.dark);
    setThemeMode(showingDark ? ThemeMode.light : ThemeMode.dark);
  }
}
