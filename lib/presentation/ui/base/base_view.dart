import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/controllers.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/models/unsplash/unsplash_model.dart';
import 'package:webcomic/data/services/api/unsplash_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/deep_link/deep_link.service.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/home_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/recents_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/settings_view.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/other_pages/categories/category_view.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/collections_view.dart';

class BaseView extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);

  @override
  _BaseViewState createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  ReceivePort _port = ReceivePort();
  List<String> bottomNavBarItems = [
    "HOME",
    "MY",
    "GENRES",
    "SETTINGS",
    "COLLECTIONS"
  ];
  List<Widget> pagesForBottomNav = [
    const HomeView(),
    const RecentsView(),
    CategoryView(category: Categories.ALL),
    SettingsView(),
  ];
  List<Widget> pagesForBottomNavWithCollection = [
    const HomeView(),
    const RecentsView(),
    CategoryView(category: Categories.ALL),
    SettingsView(),
    CollectionsView(),
  ];

  @override
  void initState() {
    doSetUp();
    baseViewPageController = PageController();
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  void doSetUp() async {
    final DatabaseHelper dbInstance = getItInstance<DatabaseHelper>();
    final DynamicLinkServiceImpl dynamicLiksService =
        getItInstance<DynamicLinkServiceImpl>();
    List<RecentlyRead>? recents = await dbInstance.getRecentReads();
    List<ChapterRead>? chaptersRead = await dbInstance.getChaptersRead();
    List<Subscribe>? subscribed = await dbInstance.getSubscriptions();
    context.read<RecentsCubit>().setResults(recents ?? []);
    context.read<ChaptersReadCubit>().setResults(chaptersRead ?? []);
    context.read<SubsCubit>().setSubs(subscribed ?? []);
    String? unsplashLinks =
        getItInstance<SharedServiceImpl>().getUnSplashLinks();

    List<Result> results = [];
    List<String> resultingLinks = [];
    if (unsplashLinks == null) {
      for (int i = 1; i < 10; i++) {
        List<Result>? res =
            await getItInstance<UnsplashApiServiceImpl>().getImages(i);
        if (res != null) {
          print("Response from unsplash ${res.length}");
          results.addAll(res);
        }
      }
      for (int i = 0; i < results.length; i++) {
        resultingLinks.add(results[i].previewPhotos[0].urls.regular);
      }
      print(results.length);
      await getItInstance<SharedServiceImpl>()
          .saveUnsplashLinks(resultingLinks.join(","));
    }

    context.read<DownloadedCubit>().refresh();
    await dynamicLiksService.handleDynamicLinks();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
  }

  List<String> bottomNavAssets = [
    "assets/Home.svg",
    "assets/User.svg",
    "assets/Favourites.svg",
    "assets/Settings.svg",
    "assets/naruto.svg"
  ];

  List<String> bottomNavItemActive = [
    "assets/Home_active.svg",
    "assets/User_active.svg",
    "assets/Favourites_active.svg",
    "assets/Settings_active.svg",
    "assets/sign.svg"
  ];

  @override
  void dispose() {
    baseViewPageController!.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness =
        WidgetsBinding.instance!.platformDispatcher.platformBrightness;
    final themeMode = getItInstance<NavigationServiceImpl>()
        .navigationKey
        .currentContext!
        .read<ThemeCubit>()
        .state
        .themeMode;
    if (themeMode == ThemeMode.system) {
      if (brightness == Brightness.light) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
            .copyWith(
                statusBarIconBrightness: Brightness.dark,
                statusBarColor: Colors.white));
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.black));
      }
    }
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      List<Map<String, dynamic>> currentlyBeingDownloaded =
          context.read<ToDownloadCubit>().state.downloads;
      List<Map<String, dynamic>> withoutCurrent = currentlyBeingDownloaded
          .where((element) => element["taskId"] != id)
          .toList();
      Map<String, dynamic> current = currentlyBeingDownloaded
          .firstWhere((element) => element["taskId"] == id, orElse: () => {});
      current["progress"] = progress;
      current["taskId"] = id;
      current["status"] = status;
      if (mounted) {
        context
            .read<ToDownloadCubit>()
            .setDownload([...withoutCurrent, current]);
        context.read<ToDownloadCubit>().removeDownloaded();
      }
    });
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // if (context.isLightMode()) {
    //   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    //     statusBarIconBrightness: Brightness.dark,
    //     statusBarBrightness: Brightness.dark,
    //     systemNavigationBarIconBrightness: Brightness.dark,
    //   ));
    // }
    // if (context.isLightMode()) {
    //   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //     statusBarIconBrightness: Brightness.dark,
    //     statusBarColor: Colors.white,
    //   ));
    // }
    return Scaffold(
      bottomNavigationBar: BlocBuilder<BottomNavigationCubit, int>(
        builder: (context, idx) {
          return BlocBuilder<ShowCollectionCubit, bool>(
              builder: (context, shouldShowCollection) {
            return BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeBloc) {
              return BottomNavigationBar(
                elevation: 2.0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: themeBloc.themeMode != ThemeMode.dark &&
                        context.isLightMode()
                    ? AppColor.vulcan
                    : Colors.white,
                unselectedItemColor: AppColor.bottomNavUnselectedColor,
                unselectedLabelStyle: TextStyle(fontSize: Sizes.dimen_11_5.sp),
                selectedLabelStyle: TextStyle(
                    fontSize: Sizes.dimen_11_5.sp,
                    color: themeBloc.themeMode != ThemeMode.dark &&
                            context.isLightMode()
                        ? AppColor.vulcan
                        : Colors.white),
                // showSelectedLabels: false,
                // showUnselectedLabels: false,
                // selectedIconTheme: const IconThemeData(color: Colors.purple),
                // unselectedIconTheme: const IconThemeData(color: Colors.white),
                // unselectedItemColor: Colors.white,
                // selectedItemColor: Colors.purple,
                currentIndex: idx,
                onTap: (int index) {
                  context.read<BottomNavigationCubit>().setPage(index);
                  baseViewPageController!.jumpToPage(index);
                },
                backgroundColor: themeBloc.themeMode != ThemeMode.dark &&
                        context.isLightMode()
                    ? Colors.white
                    : Colors.black,
                items: [
                  ...List.generate(
                      shouldShowCollection ? bottomNavBarItems.length : 4,
                      (index) {
                    return BottomNavigationBarItem(
                        tooltip: bottomNavBarItems[index],
                        icon: Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: callSvg(
                              idx == index
                                  ? bottomNavItemActive[index]
                                  : bottomNavAssets[index],
                              color: themeBloc.themeMode != ThemeMode.dark &&
                                      context.isLightMode()
                                  ? idx == index
                                      ? AppColor.vulcan
                                      : AppColor.bottomNavUnselectedColor
                                  : idx == index
                                      ? Colors.white
                                      : AppColor.bottomNavUnselectedColor,
                              width: Sizes.dimen_30,
                              height: Sizes.dimen_30),
                        ),
                        label: bottomNavBarItems[index]);
                  })
                ],
              );
            });
          });
        },
      ),
      body: BlocBuilder<BottomNavigationCubit, int>(builder: (context, idx) {
        return PageView(
            controller: baseViewPageController,
            physics: NeverScrollableScrollPhysics(),
            onPageChanged: (int index) {
              context.read<BottomNavigationCubit>().setPage(index);
            },
            children: pagesForBottomNavWithCollection);
      }),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class BottomNavItems {
  final String name;

  final Widget icon;

  BottomNavItems({required this.name, required this.icon});
}
