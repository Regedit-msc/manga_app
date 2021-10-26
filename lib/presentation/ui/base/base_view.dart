import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/controllers.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/home_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/recents_view.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/other_pages/categories/category_view.dart';

class BaseView extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);

  @override
  _BaseViewState createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  List<BottomNavItems> bottomNavBarItems = [
    BottomNavItems(
        name: "FOR YOU",
        icon: const Icon(
          Icons.home,
          color: Colors.white,
        )),
    BottomNavItems(
        name: "RECENTS",
        icon: const Icon(
          Icons.menu,
          color: Colors.white,
        )),
    BottomNavItems(
        name: "FOR YOU",
        icon: const Icon(
          Icons.phone,
          color: Colors.white,
        )),
  ];
  List<Widget> pagesForBottomNav = [
    const HomeView(),
    const RecentsView(),
    CategoryView(category: Categories.ALL),
    const Scaffold(
      backgroundColor: AppColor.violet,
    )
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
    List<RecentlyRead>? recents = await dbInstance.getRecentReads();
    List<ChapterRead>? chaptersRead = await dbInstance.getChaptersRead();
    List<Subscribe>? subscribed = await dbInstance.getSubscriptions();
    context.read<RecentsCubit>().setResults(recents ?? []);
    context.read<ChaptersReadCubit>().setResults(chaptersRead ?? []);
    context.read<SubsCubit>().setSubs(subscribed ?? []);
  }

  List<String> bottomNavAssets = [
    "assets/naruto_no_color.svg",
    "assets/goku.svg",
    "assets/naruto.svg",
    "assets/subscribed.svg"
  ];

  List<String> bottomNavItemActive = [
    "assets/home.svg",
    "assets/recents.svg",
    "assets/sign.svg",
    "assets/subscribed.svg"
  ];

  @override
  void dispose() {
    baseViewPageController!.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness =
        WidgetsBinding.instance!.platformDispatcher.platformBrightness;
    if (brightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
      ));
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.black));
    }
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
    if (context.isLightMode()) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
      ));
    }
    return Scaffold(
      bottomNavigationBar: BlocBuilder<BottomNavigationCubit, int>(
        builder: (context, idx) {
          return BottomNavigationBar(
            selectedIconTheme: const IconThemeData(color: Colors.purple),
            unselectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedItemColor: Colors.white,
            selectedItemColor: Colors.purple,
            currentIndex: idx,
            onTap: (int index) {
              context.read<BottomNavigationCubit>().setPage(index);
              baseViewPageController!.jumpToPage(index);
            },
            backgroundColor:
                context.isLightMode() ? Colors.white : Colors.black54,
            items: [
              ...List.generate(bottomNavBarItems.length, (index) {
                return BottomNavigationBarItem(
                    icon: callSvg(
                        idx == index
                            ? bottomNavItemActive[index]
                            : bottomNavAssets[index],
                        color: index != idx
                            ? context.isLightMode()
                                ? AppColor.vulcan
                                : Colors.white
                            : null,
                        width: 30.0,
                        height: 30.0),
                    label: '');
              })
            ],
          );
        },
      ),
      body: BlocBuilder<BottomNavigationCubit, int>(builder: (context, idx) {
        return PageView(
            controller: baseViewPageController,
            onPageChanged: (int index) {
              context.read<BottomNavigationCubit>().setPage(index);
            },
            children: pagesForBottomNav);
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
