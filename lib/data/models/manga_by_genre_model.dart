// To parse this JSON data, do
//
//     final mangaByGenre = mangaByGenreFromMap(jsonString);

import 'dart:convert';

MangaByGenre mangaByGenreFromMap(String str) =>
    MangaByGenre.fromMap(json.decode(str));

String mangaByGenreToMap(MangaByGenre data) => json.encode(data.toMap());

class MangaByGenre {
  MangaByGenre({
    required this.data,
  });

  final Data data;

  factory MangaByGenre.fromMap(Map<String, dynamic> json) => MangaByGenre(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };
}

class Data {
  Data({
    required this.getMangaByGenre,
  });

  final GetMangaByGenre getMangaByGenre;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        getMangaByGenre: GetMangaByGenre.fromMap(json["getMangaByGenre"]),
      );

  Map<String, dynamic> toMap() => {
        "getMangaByGenre": getMangaByGenre.toMap(),
      };
}

class GetMangaByGenre {
  GetMangaByGenre({
    required this.message,
    required this.success,
    required this.data,
  });

  final String message;
  final bool success;
  final List<Datum> data;

  factory GetMangaByGenre.fromMap(Map<String, dynamic> json) => GetMangaByGenre(
        message: json["message"],
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toMap())),
      };
}

class Datum {
  Datum({
    required this.mangaUrl,
    required this.mangaTitle,
    required this.mangaImage,
    required this.author,
    required this.stats,
    required this.summary,
  });

  final String mangaUrl;
  final String mangaTitle;
  final String mangaImage;
  final String author;
  final String stats;
  final String summary;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        mangaUrl: json["mangaUrl"],
        mangaTitle: json["mangaTitle"],
        mangaImage: json["mangaImage"],
        author: json["author"],
        stats: json["stats"],
        summary: json["summary"],
      );

  Map<String, dynamic> toMap() => {
        "mangaUrl": mangaUrl,
        "mangaTitle": mangaTitle,
        "mangaImage": mangaImage,
        "author": author,
        "stats": stats,
        "summary": summary,
      };
}
