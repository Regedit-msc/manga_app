// To parse this JSON data, do
//
//     final newestManga = newestMangaFromMap(jsonString);

import 'dart:convert';

import 'package:webcomic/domain/entities/manga_entity.dart';

NewestManga newestMangaFromMap(String str) =>
    NewestManga.fromMap(json.decode(str));

String newestMangaToMap(NewestManga data) => json.encode(data.toMap());

class NewestManga {
  NewestManga({
    this.data,
  });

  Data? data;

  factory NewestManga.fromMap(Map<String, dynamic> json) => NewestManga(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data!.toMap(),
      };
}

class Data {
  Data({
    this.getNewestManga,
  });

  GetNewestManga? getNewestManga;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        getNewestManga: GetNewestManga.fromMap(json["getNewestManga"]),
      );

  Map<String, dynamic> toMap() => {
        "getNewestManga": getNewestManga!.toMap(),
      };
}

class GetNewestManga extends ResponseEntity {
  GetNewestManga({
    this.message,
    this.success,
    this.data,
  }) : super(message: message, data: data, success: success);

  String? message;
  bool? success;
  List<Datum>? data;

  factory GetNewestManga.fromMap(Map<String, dynamic> json) => GetNewestManga(
        message: json["message"],
        success: json["success"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "data": List<dynamic>.from(data!.map((x) => x.toMap())),
      };
}

class Datum {
  Datum({
    this.title,
    this.mangaUrl,
    this.imageUrl,
  });

  String? title;
  String? mangaUrl;
  String? imageUrl;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        title: json["title"],
        mangaUrl: json["mangaUrl"],
        imageUrl: json["imageUrl"],
      );

  Map<String, dynamic> toMap() => {
        "title": title,
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
      };
}
