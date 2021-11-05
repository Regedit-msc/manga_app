import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';

extension LightMode on BuildContext {
  bool isLightMode() {
    final brightness = MediaQuery.of(this).platformBrightness;
    final theme = this.read<ThemeCubit>().state.themeMode;
    return brightness == Brightness.light && theme != ThemeMode.dark;
  }
}
