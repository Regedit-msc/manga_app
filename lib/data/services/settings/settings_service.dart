import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/data/common/constants/settings_constants.dart';
import 'package:webcomic/data/models/settings_model.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';

abstract class SettingsService {
  ThemeMode themeMode();
  Future<void> updateThemeMode(ThemeMode theme);
  Settings getSettings();
  Settings getDefaults();
  ThemeMode themeFromString(String theme);
  Future<void> updateSettings(Settings newSettings);
}

class SettingsServiceImpl extends SettingsService {
  SharedServiceImpl sharedPrefs;
  ToastServiceImpl toastServiceImpl;
  SettingsServiceImpl(
      {required this.sharedPrefs, required this.toastServiceImpl});
  @override
  ThemeMode themeMode() {
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
        await sharedPrefs.setUserThemePreference("system");
        toastServiceImpl.showToast(
            "Switched to System theme.", Toast.LENGTH_SHORT);
        return;
      case ThemeMode.dark:
        await sharedPrefs.setUserThemePreference("dark");
        toastServiceImpl.showToast(
            "Switched to Dark theme.", Toast.LENGTH_SHORT);
        return;
      case ThemeMode.light:
        await sharedPrefs.setUserThemePreference("light");
        toastServiceImpl.showToast(
            "Switched to Light theme.", Toast.LENGTH_SHORT);
        return;
      default:
        await sharedPrefs.setUserThemePreference("system");
        return;
    }
  }

  @override
  Settings getSettings() {
    String? settings = sharedPrefs.getSettings();
    if (settings != null) {
      return settingsFromMap(settings);
    }
    return settingsFromMap(jsonEncode(defaultSettingsMap));
  }

  @override
  Settings getDefaults() {
    return settingsFromMap(jsonEncode(defaultSettingsMap));
  }

  @override
  Future<void> updateSettings(Settings newSettings) async {
    await sharedPrefs.setSettings(jsonEncode(newSettings.toMap()));
    toastServiceImpl.showToast(
        "Settings successfully updated.", Toast.LENGTH_SHORT);
  }

  @override
  ThemeMode themeFromString(String theme) {
    switch (theme) {
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
}
