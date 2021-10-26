import 'package:flutter/material.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';

abstract class SettingsService {
  Future<ThemeMode> themeMode();
  Future<void> updateThemeMode(ThemeMode theme);
}

class SettingsServiceImpl extends SettingsService {
  SharedServiceImpl sharedPrefs;

  SettingsServiceImpl(this.sharedPrefs);
  @override
  Future<ThemeMode> themeMode() async {
    switch (sharedPrefs.getUserThemePreference()) {
      case "system":
        return ThemeMode.system;
      case "dark":
        return ThemeMode.dark;
      case "light":
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> updateThemeMode(ThemeMode theme) async {
    switch (theme) {
      case ThemeMode.system:
        sharedPrefs.setUserThemePreference("system");
        return;
      case ThemeMode.dark:
        sharedPrefs.setUserThemePreference("dark");
        return;
      case ThemeMode.light:
        sharedPrefs.setUserThemePreference("light");
        return;
      default:
        sharedPrefs.setUserThemePreference("system");
        return;
    }
  }
}
