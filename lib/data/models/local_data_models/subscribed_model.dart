class Subscribe {
  final String mangaUrl;

  final String title;

  final String imageUrl;

  Subscribe({
    required this.title,
    required this.mangaUrl,
    required this.imageUrl,
  });

  static const String tblName = 'subscribed';
  static const String colMangaUrl = 'mangaUrl';
  static const String colImageUrl = "imageUrl";
  static const String colTitle = "title";

  static const List<String> columnsToSelect = [
    Subscribe.colMangaUrl,
    Subscribe.colImageUrl,
    Subscribe.colTitle
  ];

  factory Subscribe.fromMap(Map<String, dynamic> json) => Subscribe(
      title: json["title"],
      mangaUrl: json["mangaUrl"],
      imageUrl: json["imageUrl"]);

  Map<String, dynamic> toMap() =>
      {"imageUrl": imageUrl, "title": title, "mangaUrl": mangaUrl};
}
