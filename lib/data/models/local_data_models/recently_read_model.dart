class RecentlyRead {
  final String mangaUrl;

  final String title;

  final String imageUrl;

  final String mostRecentReadDate;

  final String chapterUrl;

  final String chapterTitle;

  RecentlyRead({
    required this.title,
    required this.mangaUrl,
    required this.imageUrl,
    required this.chapterUrl,
    required this.chapterTitle,
    required this.mostRecentReadDate,
  });

  static const String tblName = 'recent';
  static const String colMangaUrl = 'mangaUrl';
  static const String colMostRecentReadDate = 'mostRecentReadDate';
  static const String colImageUrl = "imageUrl";
  static const String colTitle = "title";
  static const String colChapterUrl = "chapterUrl";
  static const String colChapterTitle = "chapterTitle";

  static const List<String> columnsToSelect = [
    RecentlyRead.colMangaUrl,
    RecentlyRead.colImageUrl,
    RecentlyRead.colChapterTitle,
    RecentlyRead.colChapterUrl,
    RecentlyRead.colMostRecentReadDate,
    RecentlyRead.colTitle
  ];

  factory RecentlyRead.fromMap(Map<String, dynamic> json) => RecentlyRead(
      chapterUrl: json["chapterUrl"],
      title: json["title"],
      mangaUrl: json["mangaUrl"],
      chapterTitle: json["chapterTitle"],
      mostRecentReadDate: json["mostRecentReadDate"],
      imageUrl: json["imageUrl"]);

  Map<String, dynamic> toMap() => {
        "chapterUrl": chapterUrl,
        "chapterTitle": chapterTitle,
        "imageUrl": imageUrl,
        "mostRecentReadDate": mostRecentReadDate,
        "title": title,
        "mangaUrl": mangaUrl
      };
}
