import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';

class ThemeState {
  ThemeMode themeMode;
  ThemeState({required this.themeMode});
}

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsServiceImpl settingsServiceImpl;
  ThemeCubit(this.settingsServiceImpl)
      : super(ThemeState(themeMode: ThemeMode.system));

  void initTheme() {
    ThemeState newThemeState =
        ThemeState(themeMode: settingsServiceImpl.themeMode());

    emit(newThemeState);
  }

  Future<void> updateTheme(ThemeMode newThemeMode) async {
    if (newThemeMode == state.themeMode) return;
    ThemeState newThemeState = ThemeState(themeMode: newThemeMode);

    emit(newThemeState);
    await settingsServiceImpl.updateThemeMode(newThemeMode);
  }
}
