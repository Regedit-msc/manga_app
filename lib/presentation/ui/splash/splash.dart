import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/models/google_models/user.dart';
import 'package:webcomic/data/models/settings_model.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, Routes.homeRoute);
    });
    doSetup();
    super.initState();
  }

  void doSetup() async {
    String? userDetails = getItInstance<SharedServiceImpl>().getGoogleDetails();
    if (userDetails != null) {
      context.read<ShowCollectionCubit>().setShowCollection(true);
      context
          .read<UserFromGoogleCubit>()
          .setUser(UserFromGoogle.fromMap(jsonDecode(userDetails)));
    }
    Settings settings = getItInstance<SettingsServiceImpl>().getSettings();
    context.read<SettingsCubit>().setSettings(settings);
    context.read<ThemeCubit>().initTheme();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TweenAnimationBuilder(
        duration: Duration(milliseconds: 1000),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        tween: Tween<double>(begin: 0.0, end: 1.0),
        child: Center(
          child: callSvg(
            "assets/tcomic.svg",
          ),
        ),
      ),
    );
  }
}
