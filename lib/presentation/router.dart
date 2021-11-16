import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_info_with_datum.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/ui/base/base_view.dart';
import 'package:webcomic/presentation/ui/other_pages/categories/category_view.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/add_to_collection.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/collection_main_view.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/collection_search.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/collection_subcollection_view.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/create_collection.dart';
import 'package:webcomic/presentation/ui/other_pages/download/download_page.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_info/manga_info_view.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_info/summary/summary_view.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_reader/manga_reader.dart';
import 'package:webcomic/presentation/ui/other_pages/search/search_view.dart';
import 'package:webcomic/presentation/ui/splash/splash.dart';

class CRouter {
  CRouter._();
  static Map<String, WidgetBuilder> getRoutes(RouteSettings setting) => {
        Routes.initRoute: (context) => const BaseView(),
        Routes.mangaInfo: (context) =>
            MangaInfo(mangaDetails: setting.arguments as Datum),
        Routes.mangaReader: (context) =>
            MangaReader(chapterList: setting.arguments as ChapterList),
        Routes.mangaSearch: (context) => const Search(),
        Routes.categories: (context) =>
            CategoryView(category: setting.arguments as Categories)
      };
}

class CustomRouter {
  CustomRouter._();
  static generateRoutes(setting) {
    switch (setting.name) {
      case Routes.homeRoute:
        return PageTransition(
            child: BaseView(),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.initRoute:
        return PageTransition(
            child: Splash(), type: PageTransitionType.fade, settings: setting);
      case Routes.mangaInfo:
        return PageTransition(
            child: MangaInfo(mangaDetails: setting.arguments as Datum),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.mangaReader:
        return PageTransition(
            child: MangaReader(chapterList: setting.arguments as ChapterList),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.addToCollection:
        return PageTransition(
            child: AddToCollection(
                mangaInfo: setting.arguments as MangaInfoWithDatum),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.createCollection:
        return PageTransition(
            child: CreateCollection(
                fromAddToCollectionPage: setting.arguments as bool),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.downloadView:
        return PageTransition(
            child: DownloadView(
                chapterList: setting.arguments as MangaInformationForDownload),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.addCollectionSearch:
        return PageTransition(
            child:
                AddCollectionMangaSearchView(index: setting.arguments as int),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.collectionMain:
        return PageTransition(
            child:
                CollectionMainView(collectionId: setting.arguments as String),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.subCollection:
        final data = setting.arguments as SubcollectionFields;
        return PageTransition(
            child: CollectionSubcollectionView(
              collectionId: data.collectionId,
              subCollectionId: data.subcollectionId,
            ),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.mangaSearch:
        return PageTransition(
            child: Search(), type: PageTransitionType.fade, settings: setting);
      case Routes.categories:
        return PageTransition(
            child: CategoryView(category: setting.arguments as Categories),
            type: PageTransitionType.fade,
            settings: setting);
      case Routes.summary:
        return PageTransition(
            child: SummaryView(mangaInfo: setting.arguments as GetMangaInfo),
            type: PageTransitionType.fade,
            settings: setting);
      default:
        break;
    }
  }
}

class SubcollectionFields {
  final String collectionId;

  final String subcollectionId;

  SubcollectionFields(
      {required this.collectionId, required this.subcollectionId});
}

class MangaInformationForDownload {
  final List<ChapterList> chapterList;
  final Datum mangaDetails;
  final PaletteGenerator? colorPalette;
  MangaInformationForDownload({
    required this.chapterList,
    required this.mangaDetails,
    this.colorPalette,
  });
}
