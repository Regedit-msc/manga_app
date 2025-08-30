import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
// removed old size/theme helpers not needed with M3Theme
import 'package:webcomic/data/common/screen_util/screen_util.dart';
// import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/navigation/debug_navigation_observer.dart';
import 'package:webcomic/data/services/notification/notification_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/router.dart';
// import 'package:webcomic/presentation/themes/colors.dart';
// text theme is applied inside M3Theme
import 'package:webcomic/presentation/themes/m3_theme.dart';
// import 'package:webcomic/presentation/ui/blocs/ads/ads_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/collection_cards/collection_cards_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';
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

@pragma('vm:entry-point')
void notificationTapBackground(ln.NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

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
  late ToDownloadCubit _toDownloadCubit;
  late DownloadedCubit _downloadedCubit;
  late DownloadingCubit _downloadingCubit;
  // late AdsCubit _adsCubit;
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
    _toDownloadCubit = getItInstance<ToDownloadCubit>();
    _downloadedCubit = getItInstance<DownloadedCubit>();
    _downloadingCubit = getItInstance<DownloadingCubit>();
    // _adsCubit = getItInstance<AdsCubit>();
    // Local notifications init settings (kept for future use)
    // final androidSettings =
    //     ln.AndroidInitializationSettings('@drawable/logo');
    // final iosSettings = ln.DarwinInitializationSettings(
    //   requestAlertPermission: false,
    //   requestBadgePermission: false,
    //   requestSoundPermission: false,
    // );
    // final initSettings = ln.InitializationSettings(
    //     android: androidSettings, iOS: iosSettings);
    //
    // flutterLocalNotificationsPlugin.initialize(initSetttings,
    //     onDidReceiveNotificationResponse:
    //         (ln.NotificationResponse notificationResponse) {
    //   onSelectNotification(notificationResponse.payload);
    // }, onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    setUpFcmToken();
    initFcmNotifications();
    _requestLocalNotifPermissions();
  }

  Future<void> _requestLocalNotifPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              ln.IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final ln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              ln.AndroidFlutterLocalNotificationsPlugin>();

      bool enabled =
          await androidImplementation?.areNotificationsEnabled() ?? false;
      if (!enabled) {
        await androidImplementation?.requestNotificationsPermission();
      }
    }
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
    _toDownloadCubit.close();
    _downloadedCubit.close();
    _downloadingCubit.close();
    // _adsCubit.close();
    super.dispose();
  }

  void setUpFcmToken() async {
    if (getItInstance<SharedServiceImpl>().getAddedToken()) {
      // FirebaseMessaging.instance.onTokenRefresh
      //     .listen(getItInstance<GQLRawApiServiceImpl>().updateToken);
    } else {
      // await getItInstance<GQLRawApiServiceImpl>().addToken();
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

    // obsolete helpers removed: getColor, getColorLight

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
          BlocProvider<ToDownloadCubit>.value(value: _toDownloadCubit),
          BlocProvider<DownloadedCubit>.value(value: _downloadedCubit),
          BlocProvider<DownloadingCubit>.value(value: _downloadingCubit),
          // BlocProvider<AdsCubit>.value(value: _adsCubit),
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
                MediaQueryData.fromWindow(WidgetsBinding.instance.window)
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
                navigatorObservers: [
                  getItInstance<DebugNavigationObserver>(),
                ],
                debugShowCheckedModeBanner: false,
                title: 'Tcomic',
                themeMode: themeBloc.themeMode,
                theme: M3Theme.light(),
                darkTheme: M3Theme.dark(),
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
