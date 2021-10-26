// To parse this JSON data, do
//
//     final mangaUpdates = mangaUpdatesFromMap(jsonString);

import 'dart:convert';

MangaUpdates mangaUpdatesFromMap(String str) =>
    MangaUpdates.fromMap(json.decode(str));

String mangaUpdatesToMap(MangaUpdates data) => json.encode(data.toMap());

class MangaUpdates {
  MangaUpdates({
    required this.data,
  });

  final Data data;

  factory MangaUpdates.fromMap(Map<String, dynamic> json) => MangaUpdates(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };
}

class Data {
  Data({
    required this.getMangaPage,
  });

  final GetMangaPage getMangaPage;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        getMangaPage: GetMangaPage.fromMap(json["getMangaPage"]),
      );

  Map<String, dynamic> toMap() => {
        "getMangaPage": getMangaPage.toMap(),
      };
}

class GetMangaPage {
  GetMangaPage({
    required this.message,
    required this.success,
    required this.data,
  });

  final String message;
  final bool success;
  final List<Datum> data;

  factory GetMangaPage.fromMap(Map<String, dynamic> json) => GetMangaPage(
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
    required this.status,
  });

  final String mangaUrl;
  final String imageUrl;
  final String title;
  final String status;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        mangaUrl: json["mangaUrl"],
        imageUrl: json["imageUrl"],
        title: json["title"],
        status: json["status"],
      );

  Map<String, dynamic> toMap() => {
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
        "title": title,
        "status": status,
      };
}
