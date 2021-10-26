import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/theme_controller.dart';

extension LightMode on BuildContext {
  bool isLightMode() {
    final brightness = MediaQuery.of(this).platformBrightness;
    final theme = getItInstance<ThemeController>().themeMode;
    return brightness == Brightness.light && theme != ThemeMode.dark;
  }
}
