import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/home_view.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/recents_view.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';

class BaseView extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);

  @override
  _BaseViewState createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView> {
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
    const Scaffold(
      backgroundColor: AppColor.violet,
    )
  ];

  @override
  void initState() {
    doSetUp();
    super.initState();
  }

  void doSetUp() async {
    final DatabaseHelper dbInstance = getItInstance<DatabaseHelper>();
    List<RecentlyRead>? recents = await dbInstance.getRecentReads();
    List<ChapterRead>? chaptersRead = await dbInstance.getChaptersRead();
    context.read<RecentsCubit>().setResults(recents ?? []);
    context.read<ChaptersReadCubit>().setResults(chaptersRead ?? []);
  }

  @override
  Widget build(BuildContext context) {
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
              context.read<MangaSlideShowCubit>().setIndex(1);
            },
            backgroundColor: Colors.black54,
            items: [
              ...List.generate(bottomNavBarItems.length, (index) {
                return BottomNavigationBarItem(
                    icon: bottomNavBarItems[index].icon,
                    label: bottomNavBarItems[index].name);
              })
            ],
          );
        },
      ),
      body: BlocBuilder<BottomNavigationCubit, int>(builder: (context, idx) {
        return pagesForBottomNav[idx];
      }),
    );
  }
}

class BottomNavItems {
  final String name;

  final Widget icon;

  BottomNavItems({required this.name, required this.icon});
}
