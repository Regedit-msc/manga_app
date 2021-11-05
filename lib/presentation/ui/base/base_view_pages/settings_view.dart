import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/models/settings_model.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("App Settings"),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsBloc) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  "Comics",
                  style: TextStyle(
                      fontSize: Sizes.dimen_16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SwitchListTile(
                  value: settingsBloc.settings.preloadImages,
                  onChanged: (bool value) {
                    Settings oldSettings =
                        context.read<SettingsCubit>().state.settings;
                    Settings newSettings = Settings(
                        subscribedNotifications:
                            oldSettings.subscribedNotifications,
                        preloadImages: value,
                        drawChapterColorsFromImage:
                            oldSettings.drawChapterColorsFromImage,
                        newMangaSliderDuration:
                            oldSettings.newMangaSliderDuration,
                        biometrics: oldSettings.biometrics,
                        themeMode: oldSettings.themeMode);
                    context.read<SettingsCubit>().setSettings(newSettings);
                  },
                  title: Text('Preload images'),
                  subtitle: Text(
                    "This allows prefetching of images for a better reading experience.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SwitchListTile(
                  value: settingsBloc.settings.drawChapterColorsFromImage,
                  onChanged: (bool value) {
                    Settings oldSettings =
                        context.read<SettingsCubit>().state.settings;
                    Settings newSettings = Settings(
                        subscribedNotifications:
                            oldSettings.subscribedNotifications,
                        preloadImages: oldSettings.preloadImages,
                        drawChapterColorsFromImage: value,
                        newMangaSliderDuration:
                            oldSettings.newMangaSliderDuration,
                        biometrics: oldSettings.biometrics,
                        themeMode: oldSettings.themeMode);
                    context.read<SettingsCubit>().setSettings(newSettings);
                  },
                  title: Text('Draw color from image'),
                  subtitle: Text(
                    "Use comic image colors for read chapters.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  "Notifications",
                  style: TextStyle(
                      fontSize: Sizes.dimen_16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SwitchListTile(
                  value: settingsBloc.settings.subscribedNotifications,
                  onChanged: (bool value) async {
                    Settings oldSettings =
                        context.read<SettingsCubit>().state.settings;
                    Settings newSettings = Settings(
                        subscribedNotifications: value,
                        preloadImages: oldSettings.preloadImages,
                        drawChapterColorsFromImage:
                            oldSettings.drawChapterColorsFromImage,
                        newMangaSliderDuration:
                            oldSettings.newMangaSliderDuration,
                        biometrics: oldSettings.biometrics,
                        themeMode: oldSettings.themeMode);
                    context.read<SettingsCubit>().setSettings(newSettings);
                    if (value) {
                      await getItInstance<GQLRawApiServiceImpl>().addToken();
                    } else {
                      await getItInstance<GQLRawApiServiceImpl>().removeToken();
                    }
                  },
                  title: Text('Subscribed comic notifications'),
                  subtitle: Text(
                    "Get push notifications when a comic you are subscribed to is updated.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  "Security",
                  style: TextStyle(
                      fontSize: Sizes.dimen_16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SwitchListTile(
                  value: settingsBloc.settings.biometrics,
                  onChanged: (bool value) {
                    Settings oldSettings =
                        context.read<SettingsCubit>().state.settings;
                    Settings newSettings = Settings(
                        subscribedNotifications:
                            oldSettings.subscribedNotifications,
                        preloadImages: oldSettings.preloadImages,
                        drawChapterColorsFromImage:
                            oldSettings.drawChapterColorsFromImage,
                        newMangaSliderDuration:
                            oldSettings.newMangaSliderDuration,
                        biometrics: value,
                        themeMode: oldSettings.themeMode);
                    context.read<SettingsCubit>().setSettings(newSettings);
                  },
                  title: Text('Biometrics'),
                  subtitle: Text(
                    "Use your biometrics to unlock the app.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  "Themes and preferences",
                  style: TextStyle(
                      fontSize: Sizes.dimen_16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(" App Theme"),
                        Text(
                          "Change the app theme.",
                          style: TextStyle(
                              fontSize: Sizes.dimen_14.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: settingsBloc.settings.themeMode,
                      items: <String>[
                        'system',
                        'dark',
                        'light',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.substring(0, 1).toUpperCase() +
                              value.substring(1)),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          Settings oldSettings =
                              context.read<SettingsCubit>().state.settings;
                          Settings newSettings = Settings(
                              subscribedNotifications:
                                  oldSettings.subscribedNotifications,
                              preloadImages: oldSettings.preloadImages,
                              drawChapterColorsFromImage:
                                  oldSettings.drawChapterColorsFromImage,
                              newMangaSliderDuration:
                                  oldSettings.newMangaSliderDuration,
                              biometrics: oldSettings.biometrics,
                              themeMode: val);
                          context
                              .read<SettingsCubit>()
                              .setSettings(newSettings);
                          ThemeMode newThemeMode =
                              getItInstance<SettingsServiceImpl>()
                                  .themeFromString(val);
                          context.read<ThemeCubit>().updateTheme(newThemeMode);
                        }
                      },
                      hint: Text(
                        "Choose a theme",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
