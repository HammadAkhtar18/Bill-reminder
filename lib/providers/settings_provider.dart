import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }

  static const _themeKey = 'theme_mode';
  static const _currencyKey = 'currency_code';
  static const _notificationsKey = 'notifications_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  String _currencyCode = 'USD';
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  String get currencyCode => _currencyCode;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeValue = prefs.getString(_themeKey);
    _currencyCode = prefs.getString(_currencyKey) ?? 'USD';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeValue,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> updateCurrency(String code) async {
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  Future<void> updateNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
