// To parse this JSON data, do
//
//     final mangaInformation = mangaInformationFromMap(jsonString);

import 'dart:convert';

MangaInformation mangaInformationFromMap(String str) =>
    MangaInformation.fromMap(json.decode(str));

String mangaInformationToMap(MangaInformation data) =>
    json.encode(data.toMap());

class MangaInformation {
  MangaInformation({
    required this.data,
  });

  MangaInformationData data;

  factory MangaInformation.fromMap(Map<String, dynamic> json) =>
      MangaInformation(
        data: MangaInformationData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };
}

class MangaInformationData {
  MangaInformationData({
    required this.getMangaInfo,
  });

  GetMangaInfo getMangaInfo;

  factory MangaInformationData.fromMap(Map<String, dynamic> json) =>
      MangaInformationData(
        getMangaInfo: GetMangaInfo.fromMap(json["getMangaInfo"]),
      );

  Map<String, dynamic> toMap() => {
        "getMangaInfo": getMangaInfo.toMap(),
      };
}

class GetMangaInfo {
  GetMangaInfo({
    required this.message,
    required this.success,
    required this.data,
  });

  String message;
  bool success;
  GetMangaInfoData data;

  factory GetMangaInfo.fromMap(Map<String, dynamic> json) => GetMangaInfo(
        message: json["message"],
        success: json["success"],
        data: GetMangaInfoData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "data": data.toMap(),
      };
}

class GetMangaInfoData {
  GetMangaInfoData(
      {required this.mangaImage,
      required this.author,
      required this.chapterNo,
      required this.views,
      required this.status,
      required this.description,
      required this.summary,
      required this.chapterList,
      required this.genres,
      required this.recommendations,
      required this.mangaSource
      });

  String mangaImage;
  String author;
  String chapterNo;
  String views;
  String status;
  String description;
  String summary;
  List<ChapterList> chapterList;
  List<Recommendation> recommendations;
  List<Genre> genres;
  String mangaSource;

  factory GetMangaInfoData.fromMap(Map<String, dynamic> json) =>
      GetMangaInfoData(
          mangaImage: json["mangaImage"] ?? '',
          author: json["author"] ?? "",
          chapterNo: json["chapterNo"] ?? "",
          views: json["views"] ?? "",
          status: json["status"] ?? "",
          description: json["description"] ?? "",
          summary: json["summary"] ?? "",
          chapterList: json["chapterList"].length > 0
              ? List<ChapterList>.from(
                  json["chapterList"].map((x) => ChapterList.fromMap(x)))
              : [],
          genres: List<Genre>.from(json["genres"].map((x) => Genre.fromMap(x))),
          mangaSource: json["mangaSource"] ?? '',
          recommendations: json["recommendations"].length > 0
              ? List<Recommendation>.from(
                  json["recommendations"].map((x) => Recommendation.fromMap(x)))
              : []);

  Map<String, dynamic> toMap() => {
        "mangaImage": mangaImage,
        "author": author,
        "chapterNo": chapterNo,
        "views": views,
        "status": status,
        "description": description,
        "summary": summary,
        "chapterList": List<dynamic>.from(chapterList.map((x) => x.toMap())),
        "genres": List<dynamic>.from(genres.map((x) => x.toMap())),
        "recommendations":
            List<dynamic>.from(recommendations.map((x) => x.toMap())),
        "mangaSource": mangaSource
      };
}

class ChapterList {
  String mangaTitle;

  String mangaImage;

  ChapterList(
      {required this.chapterUrl,
      required this.chapterTitle,
      required this.dateUploaded,
      required this.mangaUrl,
      required this.mangaImage,
      required this.mangaTitle});

  String chapterUrl;
  String chapterTitle;
  String dateUploaded;
  String mangaUrl;

  factory ChapterList.fromMap(Map<String, dynamic> json) => ChapterList(
      chapterUrl: json["chapterUrl"],
      chapterTitle: json["chapterTitle"],
      dateUploaded: json["dateUploaded"],
      mangaUrl: json["mangaUrl"] ?? "",
      mangaTitle: json["mangaTitle"] ?? '',
      mangaImage: json["mangaImage"] ?? '');

  Map<String, dynamic> toMap() => {
        "chapterUrl": chapterUrl,
        "chapterTitle": chapterTitle,
        "dateUploaded": dateUploaded,
        "mangaUrl": mangaUrl,
        "mangaTitle": mangaTitle,
        "mangaImage": mangaImage
      };
}

class Genre {
  Genre({
    required this.genreUrl,
    required this.genre,
  });

  final String genreUrl;
  final String genre;

  factory Genre.fromMap(Map<String, dynamic> json) => Genre(
        genreUrl: json["genreUrl"],
        genre: json["genre"],
      );

  Map<String, dynamic> toMap() => {
        "genreUrl": genreUrl,
        "genre": genre,
      };
}

class Recommendation {
  Recommendation(
      {required this.title, required this.mangaUrl, required this.mangaImage});

  final String mangaImage;
  final String mangaUrl;
  final String title;

  factory Recommendation.fromMap(Map<String, dynamic> json) => Recommendation(
      title: json["title"],
      mangaUrl: json["mangaUrl"],
      mangaImage: json["mangaImage"]);

  Map<String, dynamic> toMap() =>
      {"title": title, "mangaUrl": mangaUrl, "mangaImage": mangaImage};
}
