import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';

extension LightMode on BuildContext {
  bool isLightMode() {
    final brightness = MediaQuery.of(this).platformBrightness;
    final theme = this.read<ThemeCubit>().state.themeMode;
    if (theme == ThemeMode.dark) {
      return false;
    } else if (theme == ThemeMode.light) {
      return true;
    } else {
      if (brightness == Brightness.light) {
        return true;
      } else {
        return false;
      }
    }
  }
}
