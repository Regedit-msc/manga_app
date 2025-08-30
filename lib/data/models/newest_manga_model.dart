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

  @override
  String toString() => 'NewestManga(data: ${data?.toString()})';
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

  @override
  String toString() =>
      'NewestManga.Data(getNewestManga: ${getNewestManga?.toString()})';
}

class GetNewestManga extends ResponseEntity {
  GetNewestManga({
    this.message,
    this.success,
    this.data,
  }) : super(message: message, data: data, success: success);

  final String? message;
  final bool? success;
  final List<Datum>? data;

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

  @override
  String toString() =>
      'GetNewestManga(success: $success, message: $message, items: ${data?.length ?? 0})';
}

class Datum {
  Datum({
    this.title,
    this.mangaUrl,
    this.imageUrl,
    this.mangaSource,
  });

  String? title;
  String? mangaUrl;
  String? imageUrl;
  String? mangaSource;

  factory Datum.fromMap(Map<String, dynamic> json) => Datum(
        title: json["title"],
        mangaUrl: json["mangaUrl"],
        imageUrl: json["imageUrl"],
        mangaSource: json["mangaSource"],
      );

  Map<String, dynamic> toMap() => {
        "title": title,
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
        "mangaSource": mangaSource,
      };

  @override
  String toString() =>
      'NewestManga.Item(title: $title, url: $mangaUrl, source: $mangaSource)';
}
