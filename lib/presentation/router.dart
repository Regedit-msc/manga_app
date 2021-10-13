import 'package:flutter/cupertino.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/ui/base/base_view.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_info/manga_info_view.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_reader/manga_reader.dart';

class CRouter {
  CRouter._();
  static Map<String, WidgetBuilder> getRoutes(RouteSettings setting) => {
        Routes.initRoute: (context) => const BaseView(),
        Routes.mangaInfo: (context) =>
            MangaInfo(mangaDetails: setting.arguments as Datum),
        Routes.mangaReader: (context) =>
            MangaReader(chapterList: setting.arguments as ChapterList)
      };
}
