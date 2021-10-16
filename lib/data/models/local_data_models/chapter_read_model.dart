class ChapterRead {
  final String mangaUrl;

  final String chapterUrl;

  ChapterRead({
    required this.mangaUrl,
    required this.chapterUrl,
  });

  static const String tblName = 'chapterread';
  static const String colMangaUrl = 'mangaUrl';
  static const String colChapterUrl = "chapterUrl";

  static const List<String> columnsToSelect = [
    ChapterRead.colMangaUrl,
    ChapterRead.colChapterUrl
  ];

  factory ChapterRead.fromMap(Map<String, dynamic> json) =>
      ChapterRead(mangaUrl: json["mangaUrl"], chapterUrl: json["chapterUrl"]);

  Map<String, dynamic> toMap() =>
      {"chapterUrl": chapterUrl, "mangaUrl": mangaUrl};
}
