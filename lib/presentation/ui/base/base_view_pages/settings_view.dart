import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:webcomic/data/common/constants/size_constants.dart';
// import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/models/settings_model.dart';
// import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/cache/cache_service.dart';
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("App Settings"),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsBloc) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    "Comics",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile.adaptive(
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
                    title: const Text('Preload images'),
                    subtitle: Text(
                      "This allows prefetching of images for a better reading experience.",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile.adaptive(
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
                    title: const Text('Draw color from image'),
                    subtitle: Text(
                      "Use comic image colors for read chapters.",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    "Notifications",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile.adaptive(
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
                        // await getItInstance<GQLRawApiServiceImpl>().addToken();
                      } else {
                        // await getItInstance<GQLRawApiServiceImpl>()
                        //     .removeToken();
                      }
                    },
                    title: const Text('Subscribed comic notifications'),
                    subtitle: Text(
                      "Get push notifications when a comic you are subscribed to is updated.",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    "Security",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile.adaptive(
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
                    title: const Text('Biometrics'),
                    subtitle: Text(
                      "Use your biometrics to unlock the app.",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    "Themes and preferences",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "App Theme",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: settingsBloc.settings.themeMode,
                        decoration: const InputDecoration(
                          labelText: 'Theme',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'system', child: Text('System')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                          DropdownMenuItem(
                              value: 'light', child: Text('Light')),
                        ],
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
                            context
                                .read<ThemeCubit>()
                                .updateTheme(newThemeMode);
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Change the app theme.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    "Storage",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6),
                  onTap: () {
                    getItInstance<CacheServiceImpl>().clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  },
                  title: const Text('Cache'),
                  subtitle: Text(
                    'Tap to clear image cache.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.cleaning_services_rounded,
                      color: scheme.primary),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
