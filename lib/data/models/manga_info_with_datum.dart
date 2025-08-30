import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';

class MangaInfoWithDatum {
  GetMangaInfo? mangaInfo;

  Datum datum;

  MangaInfoWithDatum({required this.mangaInfo, required this.datum});

  @override
  String toString() =>
      'MangaInfoWithDatum(infoSuccess: ${mangaInfo?.success.toString() ?? 'null'}, datum: ${datum.title})';
}
