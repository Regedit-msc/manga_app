class Subscribe {
  final String mangaUrl;

  final String title;

  final String imageUrl;

  final String dateSubscribed;

  Subscribe(
      {required this.title,
      required this.mangaUrl,
      required this.imageUrl,
      required this.dateSubscribed});

  static const String tblName = 'subscribed';
  static const String colMangaUrl = 'mangaUrl';
  static const String colImageUrl = "imageUrl";
  static const String colTitle = "title";
  static const String colDateSubscribed = "dateSubscribed";
  static const List<String> columnsToSelect = [
    Subscribe.colMangaUrl,
    Subscribe.colImageUrl,
    Subscribe.colTitle,
    Subscribe.colDateSubscribed
  ];

  factory Subscribe.fromMap(Map<String, dynamic> json) => Subscribe(
      title: json["title"],
      mangaUrl: json["mangaUrl"],
      imageUrl: json["imageUrl"],
      dateSubscribed: json["dateSubscribed"]);

  Map<String, dynamic> toMap() => {
        "imageUrl": imageUrl,
        "title": title,
        "mangaUrl": mangaUrl,
        "dateSubscribed": dateSubscribed
      };
}
