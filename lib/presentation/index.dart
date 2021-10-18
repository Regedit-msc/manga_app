import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/notification/notification_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/fade_page_route_builder.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';

import '../main.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

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
  @override
  void initState() {
    super.initState();
    _recentsCubit = getItInstance<RecentsCubit>();
    _chaptersReadCubit = getItInstance<ChaptersReadCubit>();
    _bottomNavigationCubit = getItInstance<BottomNavigationCubit>();
    _mangaSlideShowCubit = getItInstance<MangaSlideShowCubit>();
    _mangaResultsCubit = getItInstance<MangaResultsCubit>();
    _subsCubit = getItInstance<SubsCubit>();
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
        ],
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Manga App',
          theme: ThemeData(
              scaffoldBackgroundColor: AppColor.vulcan,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: ThemeText.getTextTheme(),
              appBarTheme: const AppBarTheme(elevation: 0)),
          // darkTheme: ThemeData.dark(),
          initialRoute: Routes.initRoute,
          onGenerateRoute: (RouteSettings settings) {
            final routes = CRouter.getRoutes(settings);
            final WidgetBuilder? builder = routes[settings.name];
            return FadePageRouteBuilder(
              builder: builder!,
              settings: settings,
            );
          },
          builder: (context, child) {
            return child!;
          },
        ),
      ),
    );
  }
}

void onSelectNotification(String? payload) {
  print("$payload");
}
