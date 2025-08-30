// To parse this JSON data, do
//
//     final mostViewedManga = mostViewedMangaFromMap(jsonString);

import 'dart:convert';

MostViewedManga mostViewedMangaFromMap(String str) =>
    MostViewedManga.fromMap(json.decode(str));

String mostViewedMangaToMap(MostViewedManga data) => json.encode(data.toMap());

class MostViewedManga {
  MostViewedManga({
    required this.data,
  });

  final Data data;

  factory MostViewedManga.fromMap(Map<String, dynamic> json) => MostViewedManga(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };

  @override
  String toString() => 'MostViewedManga(data: ${data.toString()})';
}

class Data {
  Data({
    required this.getMostViewedManga,
  });

  final GetMostViewedManga getMostViewedManga;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        getMostViewedManga:
            GetMostViewedManga.fromMap(json["getMostViewedManga"]),
      );

  Map<String, dynamic> toMap() => {
        "getMostViewedManga": getMostViewedManga.toMap(),
      };

  @override
  String toString() =>
      'MostViewedManga.Data(getMostViewedManga: ${getMostViewedManga.toString()})';
}

class GetMostViewedManga {
  GetMostViewedManga({
    required this.message,
    required this.success,
    required this.data,
  });

  final String message;
  final bool success;
  final List<Datum> data;

  factory GetMostViewedManga.fromMap(Map<String, dynamic> json) =>
      GetMostViewedManga(
        message: json["message"],
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toMap())),
      };

  @override
  String toString() =>
      'GetMostViewedManga(success: ' +
      success.toString() +
      ', items: ' +
      data.length.toString() +
      ')';
}

class Datum {
  Datum({
    required this.mangaUrl,
    required this.imageUrl,
    required this.title,
    required this.status,
    required this.mangaSource,
  });

  final String mangaUrl;
  final String imageUrl;
  final String title;
  final String status;
  final String mangaSource;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        mangaUrl: json["mangaUrl"],
        imageUrl: json["imageUrl"],
        title: json["title"],
        status: json["status"],
        mangaSource: json["mangaSource"],
      );

  Map<String, dynamic> toMap() => {
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
        "title": title,
        "status": status,
        "mangaSource": mangaSource,
      };
}
