import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/settings_constants.dart';
import 'package:webcomic/data/models/settings_model.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';

class SettingsState {
  Settings settings;
  SettingsState({required this.settings});
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsServiceImpl settingsService;

  SettingsCubit({required this.settingsService})
      : super(SettingsState(
            settings: settingsFromMap(jsonEncode(defaultSettingsMap))));

  void setSettings(Settings newSettings) async {
    emit(SettingsState(settings: newSettings));
    await settingsService.updateSettings(newSettings);
  }
}
