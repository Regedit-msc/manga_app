// To parse this JSON data, do
//
//     final settings = settingsFromMap(jsonString);

import 'dart:convert';

Settings settingsFromMap(String str) => Settings.fromMap(json.decode(str));

String settingsToMap(Settings data) => json.encode(data.toMap());

class Settings {
  Settings(
      {required this.preloadImages,
      required this.drawChapterColorsFromImage,
      required this.newMangaSliderDuration,
      required this.biometrics,
      required this.subscribedNotifications,
      required this.themeMode});

  final bool preloadImages;
  final String themeMode;
  final bool drawChapterColorsFromImage;
  final int newMangaSliderDuration;
  final bool biometrics;
  final bool subscribedNotifications;
  factory Settings.fromMap(Map<String, dynamic> json) => Settings(
      preloadImages: json["preloadImages"],
      drawChapterColorsFromImage: json["drawChapterColorsFromImage"],
      newMangaSliderDuration: json["newMangaSliderDuration"],
      biometrics: json["biometrics"],
      subscribedNotifications: json["subscribedNotifications"],
      themeMode: json["themeMode"]);

  Map<String, dynamic> toMap() => {
        "preloadImages": preloadImages,
        "drawChapterColorsFromImage": drawChapterColorsFromImage,
        "newMangaSliderDuration": newMangaSliderDuration,
        "biometrics": biometrics,
        "subscribedNotifications": subscribedNotifications,
        "themeMode": themeMode
      };
}
