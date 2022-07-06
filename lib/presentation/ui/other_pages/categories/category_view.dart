import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/other_pages/categories/category_pages/category_pages_main.dart';

class CategoryView extends StatefulWidget {
  final Categories? category;

  const CategoryView({Key? key, this.category}) : super(key: key);

  @override
  _CategoryViewState createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  int getInitialIndex(Categories? category) {
    switch (category) {
      case Categories.ACTION:
        return 0;
      case Categories.MARTIAL_ARTS:
        return 1;
      case Categories.ALL:
        return 2;
      case Categories.HAREM:
        return 3;
      case Categories.DRAMA:
        return 4;
      case Categories.SPORTS:
        return 5;
      case Categories.SCHOOL_LIFE:
        return 6;
      case Categories.ADULT:
        return 7;
      case Categories.SLICE_OF_LIFE:
        return 8;
      case Categories.WEBTOONS:
        return 9;
      case Categories.ROMANCE:
        return 10;
      case Categories.SCI_FI:
        return 11;
      case Categories.MYSTERIOUS:
        return 12;
      case Categories.MATURE:
        return 13;
      case Categories.TRAGEDY:
        return 14;
      case Categories.ECCHI:
        return 15;
      case Categories.SHOUJO:
        return 16;
      case Categories.SHOUNEN:
        return 17;
      case Categories.MECHA:
        return 18;
      case Categories.MEDICAL:
        return 19;
      case Categories.FANTASY:
        return 20;
      case Categories.GENDER_BENDER:
        return 21;
      case Categories.HISTORICAL:
        return 22;
      case Categories.HORROR:
        return 23;
      case Categories.COOKING:
        return 24;
      case Categories.COMEDY:
        return 25;
      case Categories.MANHUA:
        return 26;
      case Categories.MANHWA:
        return 27;
      case Categories.PSYCHOLOGICAL:
        return 28;
      case Categories.ONE_SHOT:
        return 29;
      case Categories.ISEKAI:
        return 30;
      case Categories.ADVENTURE:
        return 31;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    _tabController = TabController(
        initialIndex: getInitialIndex(widget.category),
        vsync: this,
        length: tabs.length);
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  List<String> tabs = [
    "Action",
    "Martial Arts",
    "All",
    "Harem",
    "Drama",
    "Sports",
    "School Life",
    "Adult",
    "Slice of life",
    "Webtoons",
    "Romance",
    "Sci fi",
    "Mysterious",
    "Mature",
    "Tragedy",
    "Ecchi",
    "Shoujo",
    "Shounen",
    "Mecha",
    "Medical",
    "Fantasy",
    "Gender bender",
    "Historical",
    "Horror",
    "Cooking",
    "Comedy",
    "Manhua",
    "Manhwa",
    "Psychological",
    "One shot",
    "Isekai",
    "Adventure",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Genres"),
        bottom: TabBar(
          indicatorColor: context.isLightMode() ? AppColor.vulcan : null,
          isScrollable: true,
          controller: _tabController,
          tabs: [
            ...List.generate(tabs.length, (index) {
              return Tab(
                child: Text(tabs[index].toUpperCase()),
              );
            })
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ...List.generate(tabs.length, (index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: CategoryViewMain(category: tabs[index]),
            );
          })
        ],
      ),
    );
  }
}
