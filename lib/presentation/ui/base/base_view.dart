import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/controllers.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/models/unsplash/unsplash_model.dart';
import 'package:webcomic/data/services/api/unsplash_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/home_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/recents_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/settings_view.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/other_pages/categories/category_view.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/collections_view.dart';
import 'package:webcomic/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:webcomic/presentation/widgets/download/download_widgets.dart';

/// flutter_downloader background callback must be a top-level entry-point
/// so the VM can find it in AOT mode.
@pragma('vm:entry-point')
void downloaderCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class BaseView extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);

  @override
  _BaseViewState createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  ReceivePort _port = ReceivePort();
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
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void doSetUp() async {
    final DatabaseHelper dbInstance = getItInstance<DatabaseHelper>();
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
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloaderCallback);
  }

  // Bottom nav icon assets moved into AppBottomNavBar widget for cohesion.

  @override
  void dispose() {
    baseViewPageController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
      final String id = data[0] as String;
      final int rawStatus = data[1] is int ? data[1] as int : 0;
      final int progress = data[2] is int ? data[2] as int : 0;
      // Map the raw integer emitted by flutter_downloader into enum safely
      final DownloadTaskStatus status =
          (rawStatus >= 0 && rawStatus < DownloadTaskStatus.values.length)
              ? DownloadTaskStatus.values[rawStatus]
              : DownloadTaskStatus.undefined;
      if (mounted) {
        context.read<DownloadingCubit>().onTaskUpdate(id, status, progress);
      }
    });
  }

  // callback moved to top-level (see downloaderCallback above)

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
      bottomNavigationBar: const AppBottomNavBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Global download progress bar
              GlobalDownloadProgressBar(),
              Expanded(
                child: BlocListener<BottomNavigationCubit, int>(
                  listener: (context, idx) {
                    // Keep the PageView in sync without rebuilding AppBottomNavBar.
                    baseViewPageController?.jumpToPage(idx);
                  },
                  child: PageView(
                    controller: baseViewPageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int index) {
                      context.read<BottomNavigationCubit>().setPage(index);
                    },
                    children: pagesForBottomNavWithCollection,
                  ),
                ),
              ),
            ],
          ),
          // Floating download indicator
          FloatingDownloadIndicator(
            onTap: () {
              // Navigate to download queue page when implemented
              // Navigator.pushNamed(context, '/download-queue');
            },
          ),
        ],
      ),
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
