// To parse this JSON data, do
//
//     final mangaReader = mangaReaderFromMap(jsonString);

import 'dart:convert';

MangaReader mangaReaderFromMap(String str) =>
    MangaReader.fromMap(json.decode(str));

String mangaReaderToMap(MangaReader data) => json.encode(data.toMap());

class MangaReader {
  MangaReader({
    required this.data,
  });

  MangaReaderData data;

  factory MangaReader.fromMap(Map<String, dynamic> json) => MangaReader(
        data: MangaReaderData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };
}

class MangaReaderData {
  MangaReaderData({
    required this.getMangaReader,
  });

  GetMangaReader getMangaReader;

  factory MangaReaderData.fromMap(Map<String, dynamic> json) => MangaReaderData(
        getMangaReader: GetMangaReader.fromMap(json["getMangaReader"]),
      );

  Map<String, dynamic> toMap() => {
        "getMangaReader": getMangaReader.toMap(),
      };
}

class GetMangaReader {
  GetMangaReader({
    required this.message,
    required this.success,
    required this.data,
  });

  String message;
  bool success;
  GetMangaReaderData data;

  factory GetMangaReader.fromMap(Map<String, dynamic> json) => GetMangaReader(
        message: json["message"],
        success: json["success"],
        data: GetMangaReaderData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "data": data.toMap(),
      };
}

class GetMangaReaderData {
  GetMangaReaderData(
      {required this.chapter,
      required this.images,
      this.chapterList,
      this.mangaSource});

  String chapter;
  List<String>? chapterList;
  List<String> images;
  String? mangaSource;

  factory GetMangaReaderData.fromMap(Map<String, dynamic> json) =>
      GetMangaReaderData(
          chapter: json["chapter"] ?? '',
          images: List<String>.from(json["images"].map((x) => x)),
          chapterList: json["chapterList"] != null
              ? List<String>.from(json["chapterList"].map((x) => x))
              : [],
          mangaSource: json["mangaSource"] ?? '');

  Map<String, dynamic> toMap() => {
        "chapter": chapter,
        "images": List<dynamic>.from(images.map((x) => x)),
        "chapterList": List<dynamic>.from(chapterList!.map((x) => x)),
        "mangaSource": mangaSource,
      };
}
