import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/notification/notification_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/collection_cards/collection_cards_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_updates/manga_updates_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';

import '../main.dart';

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  late BottomNavigationCubit _bottomNavigationCubit;
  late MangaSlideShowCubit _mangaSlideShowCubit;
  late MangaResultsCubit _mangaResultsCubit;
  late ChaptersReadCubit _chaptersReadCubit;
  late RecentsCubit _recentsCubit;
  late SubsCubit _subsCubit;
  late MangaUpdatesCubit _mangaUpdatesCubit;
  late ShowCollectionCubit _showCollectionCubit;
  late UserFromGoogleCubit _userFromGoogleCubit;
  late CollectionCardsCubit _collectionCardsCubit;
  late SettingsCubit _settingsCubit;
  late ThemeCubit _themeCubit;
  @override
  void initState() {
    super.initState();
    // FlutterBranchSdk.validateSDKIntegration();
    _recentsCubit = getItInstance<RecentsCubit>();
    _mangaUpdatesCubit = getItInstance<MangaUpdatesCubit>();
    _mangaSlideShowCubit = getItInstance<MangaSlideShowCubit>();
    _showCollectionCubit = getItInstance<ShowCollectionCubit>();
    _chaptersReadCubit = getItInstance<ChaptersReadCubit>();
    _bottomNavigationCubit = getItInstance<BottomNavigationCubit>();
    _mangaSlideShowCubit = getItInstance<MangaSlideShowCubit>();
    _mangaResultsCubit = getItInstance<MangaResultsCubit>();
    _subsCubit = getItInstance<SubsCubit>();
    _userFromGoogleCubit = getItInstance<UserFromGoogleCubit>();
    _collectionCardsCubit = getItInstance<CollectionCardsCubit>();
    _settingsCubit = getItInstance<SettingsCubit>();
    _themeCubit = getItInstance<ThemeCubit>();
    var initializationSettingsAndroid =
        ln.AndroidInitializationSettings('@drawable/logo');
    var initializationSettingsIOs = ln.IOSInitializationSettings();
    var initSetttings = ln.InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOs);

    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);

    setUpFcmToken();
    initFcmNotifications();
  }

  @override
  void dispose() {
    _recentsCubit.close();
    _bottomNavigationCubit.close();
    _mangaSlideShowCubit.close();
    _mangaResultsCubit.close();
    _chaptersReadCubit.close();
    _subsCubit.close();
    _mangaUpdatesCubit.close();
    _showCollectionCubit.close();
    _userFromGoogleCubit.close();
    _collectionCardsCubit.close();
    _settingsCubit.close();
    _themeCubit.close();
    super.dispose();
  }

  void setUpFcmToken() async {
    if (getItInstance<SharedServiceImpl>().getAddedToken()) {
      FirebaseMessaging.instance.onTokenRefresh
          .listen(getItInstance<GQLRawApiServiceImpl>().updateToken);
    } else {
      await getItInstance<GQLRawApiServiceImpl>().addToken();
    }
  }

  void initFcmNotifications() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage? message) async {
      print("onMessage");
      RemoteNotification? notification = message!.notification;
      await NotificationService.showNotification(
          notification!.body,
          notification.title,
          json.encode({
            "title": message.notification!.title,
            "body": message.notification!.body,
            "imageUrl": message.notification!.android!.imageUrl
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.black,
    //   statusBarColor: Colors.transparent,
    // ));

    Color? getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return AppColor.violet;
      }
      return Colors.grey[800];
    }

    Color? getColorLight(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return AppColor.vulcan;
      }
      return Colors.grey[200];
    }

    return GraphQLProvider(
      client: getItInstance<ValueNotifier<GraphQLClient>>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BottomNavigationCubit>.value(
              value: _bottomNavigationCubit),
          BlocProvider<MangaSlideShowCubit>.value(value: _mangaSlideShowCubit),
          BlocProvider<MangaResultsCubit>.value(value: _mangaResultsCubit),
          BlocProvider<RecentsCubit>.value(value: _recentsCubit),
          BlocProvider<ChaptersReadCubit>.value(value: _chaptersReadCubit),
          BlocProvider<SubsCubit>.value(value: _subsCubit),
          BlocProvider<MangaUpdatesCubit>.value(value: _mangaUpdatesCubit),
          BlocProvider<UserFromGoogleCubit>.value(value: _userFromGoogleCubit),
          BlocProvider<ShowCollectionCubit>.value(value: _showCollectionCubit),
          BlocProvider<CollectionCardsCubit>.value(
              value: _collectionCardsCubit),
          BlocProvider<SettingsCubit>.value(value: _settingsCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
        ],
        child:
            BlocBuilder<ThemeCubit, ThemeState>(builder: (context, themeBloc) {
          if (themeBloc.themeMode == ThemeMode.dark) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
                .copyWith(
                    statusBarIconBrightness: Brightness.light,
                    statusBarColor: Colors.black));
          } else if (themeBloc.themeMode == ThemeMode.light) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
                .copyWith(
                    statusBarIconBrightness: Brightness.dark,
                    statusBarColor: Colors.white));
          } else {
            final brightness =
                MediaQueryData.fromWindow(WidgetsBinding.instance!.window)
                    .platformBrightness;
            if (brightness == Brightness.light) {
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
                  .copyWith(
                      statusBarIconBrightness: Brightness.dark,
                      statusBarColor: Colors.white));
            } else {
              SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
                  .copyWith(
                      statusBarIconBrightness: Brightness.light,
                      statusBarColor: Colors.black));
            }
          }
          return AnimatedSwitcher(
              duration: Duration(seconds: 1),
              child: MaterialApp(
                navigatorKey:
                    getItInstance<NavigationServiceImpl>().navigationKey,
                debugShowCheckedModeBanner: false,
                title: 'Webcomic',
                themeMode: themeBloc.themeMode,
                theme: ThemeData(
                  scaffoldBackgroundColor: Colors.white,
                  brightness: Brightness.light,
                  indicatorColor: AppColor.vulcan,
                  tabBarTheme: TabBarTheme(
                      unselectedLabelColor: Colors.grey,
                      unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.dimen_14.sp),
                      labelColor: AppColor.vulcan,
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: Sizes.dimen_14.sp)),
                  appBarTheme: AppBarTheme(
                      iconTheme: IconThemeData(color: Colors.black),
                      elevation: 0.0,
                      backgroundColor: Colors.white,
                      titleTextStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: Sizes.dimen_22.sp)),
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  textTheme: ThemeText.getTextLightTheme(),
                  switchTheme: SwitchThemeData(
                    thumbColor: MaterialStateProperty.all(AppColor.vulcan),
                    trackColor: MaterialStateProperty.resolveWith(getColorLight),
                  ),
                ),
                darkTheme: ThemeData(
                    switchTheme: SwitchThemeData(
                      thumbColor: MaterialStateProperty.all(AppColor.violet),
                      trackColor: MaterialStateProperty.resolveWith(getColor),
                    ),
                    brightness: Brightness.dark,
                    indicatorColor: Colors.white,
                    scaffoldBackgroundColor: AppColor.vulcan,
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    textTheme: ThemeText.getTextTheme(),
                    appBarTheme: const AppBarTheme(
                      iconTheme: IconThemeData(color: Colors.white),
                      elevation: 0,
                      backgroundColor: AppColor.vulcan,
                    )),
                initialRoute: Routes.initRoute,
                onGenerateRoute: (settings) =>
                    CustomRouter.generateRoutes(settings),
              ));
        }),
      ),
    );
  }
}

void onSelectNotification(String? payload) {
  print("$payload");
}
