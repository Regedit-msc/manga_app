class ReadProgress {
  final String mangaUrl;
  final String chapterUrl;
  final int lastPageIndex; // zero-based
  final int totalPages;
  final String updatedAt; // ISO8601 string

  ReadProgress({
    required this.mangaUrl,
    required this.chapterUrl,
    required this.lastPageIndex,
    required this.totalPages,
    required this.updatedAt,
  });

  static const String tblName = 'readprogress';
  static const String colMangaUrl = 'mangaUrl';
  static const String colChapterUrl = 'chapterUrl';
  static const String colLastPageIndex = 'lastPageIndex';
  static const String colTotalPages = 'totalPages';
  static const String colUpdatedAt = 'updatedAt';

  static const List<String> columnsToSelect = [
    colMangaUrl,
    colChapterUrl,
    colLastPageIndex,
    colTotalPages,
    colUpdatedAt,
  ];

  factory ReadProgress.fromMap(Map<String, dynamic> json) => ReadProgress(
        mangaUrl: json[colMangaUrl] as String,
        chapterUrl: json[colChapterUrl] as String,
        lastPageIndex: (json[colLastPageIndex] as num).toInt(),
        totalPages: (json[colTotalPages] as num).toInt(),
        updatedAt: json[colUpdatedAt] as String,
      );

  Map<String, dynamic> toMap() => {
        colMangaUrl: mangaUrl,
        colChapterUrl: chapterUrl,
        colLastPageIndex: lastPageIndex,
        colTotalPages: totalPages,
        colUpdatedAt: updatedAt,
      };
}
