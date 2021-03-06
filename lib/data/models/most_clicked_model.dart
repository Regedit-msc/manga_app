// To parse this JSON data, do
//
//     final mostClickedManga = mostClickedMangaFromMap(jsonString);

import 'dart:convert';

MostClickedManga mostClickedMangaFromMap(String str) =>
    MostClickedManga.fromMap(json.decode(str));

String mostClickedMangaToMap(MostClickedManga data) =>
    json.encode(data.toMap());

class MostClickedManga {
  MostClickedManga({
    required this.data,
  });

  final Data data;

  factory MostClickedManga.fromMap(Map<String, dynamic> json) =>
      MostClickedManga(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };
}

class Data {
  Data({
    required this.getMostClickedManga,
  });

  final GetMostClickedManga getMostClickedManga;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        getMostClickedManga:
            GetMostClickedManga.fromMap(json["getMostClickedManga"]),
      );

  Map<String, dynamic> toMap() => {
        "getMostClickedManga": getMostClickedManga.toMap(),
      };
}

class GetMostClickedManga {
  GetMostClickedManga({
    required this.message,
    required this.success,
    required this.data,
  });

  final String message;
  final bool success;
  final List<Datum> data;

  factory GetMostClickedManga.fromMap(Map<String, dynamic> json) =>
      GetMostClickedManga(
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
    required this.imageUrl,
    required this.title,
    required this.score,
  });

  final String mangaUrl;
  final String imageUrl;
  final String title;
  final String score;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        mangaUrl: json["mangaUrl"],
        imageUrl: json["imageUrl"],
        title: json["title"],
        score: json["score"],
      );

  Map<String, dynamic> toMap() => {
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
        "title": title,
        "score": score,
      };
}
