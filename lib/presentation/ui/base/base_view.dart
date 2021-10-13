import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/home_view.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

class BaseView extends StatefulWidget {
  const BaseView({Key? key}) : super(key: key);

  @override
  _BaseViewState createState() => _BaseViewState();
}

class _BaseViewState extends State<BaseView> {
  List<BottomNavItems> bottomNavBarItems = [
    BottomNavItems(name: "FOR YOU", icon: const Icon(Icons.home)),
    BottomNavItems(name: "FOR YOU", icon: const Icon(Icons.menu)),
    BottomNavItems(name: "FOR YOU", icon: const Icon(Icons.phone)),
  ];
  List<Widget> pagesForBottomNav = [
    HomeView(),
    Scaffold(
      backgroundColor: AppColor.royalBlue,
    ),
    Scaffold(
      backgroundColor: AppColor.violet,
    )
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BlocBuilder<BottomNavigationCubit, int>(
        builder: (context, idx) {
          return BottomNavigationBar(
            currentIndex: idx,
            onTap: (int index) {
              context.read<BottomNavigationCubit>().setPage(index);
              context.read<MangaSlideShowCubit>().setIndex(1);
            },
            backgroundColor: AppColor.royalBlue,
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
