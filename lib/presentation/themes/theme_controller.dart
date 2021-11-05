import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';

class ThemeController with ChangeNotifier {
  final SettingsServiceImpl settingsServiceImpl;
  ThemeController(this.settingsServiceImpl);
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  void loadTheme() {
    _themeMode = settingsServiceImpl.themeMode();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;
    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await settingsServiceImpl.updateThemeMode(newThemeMode);
  }
}
