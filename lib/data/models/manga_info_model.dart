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
  GetMangaInfoData({
    required this.mangaImage,
    required this.author,
    required this.chapterNo,
    required this.views,
    required this.status,
    required this.description,
    required this.summary,
    required this.chapterList,
  });

  String mangaImage;
  String author;
  String chapterNo;
  String views;
  String status;
  String description;
  String summary;
  List<ChapterList> chapterList;

  factory GetMangaInfoData.fromMap(Map<String, dynamic> json) =>
      GetMangaInfoData(
        mangaImage: json["mangaImage"],
        author: json["author"],
        chapterNo: json["chapterNo"],
        views: json["views"],
        status: json["status"],
        description: json["description"],
        summary: json["summary"],
        chapterList: List<ChapterList>.from(
            json["chapterList"].map((x) => ChapterList.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "mangaImage": mangaImage,
        "author": author,
        "chapterNo": chapterNo,
        "views": views,
        "status": status,
        "description": description,
        "summary": summary,
        "chapterList": List<dynamic>.from(chapterList.map((x) => x.toMap())),
      };
}

class ChapterList {
  ChapterList({
    required this.chapterUrl,
    required this.chapterTitle,
    required this.dateUploaded,
  });

  String chapterUrl;
  String chapterTitle;
  String dateUploaded;

  factory ChapterList.fromMap(Map<String, dynamic> json) => ChapterList(
        chapterUrl: json["chapterUrl"],
        chapterTitle: json["chapterTitle"],
        dateUploaded: json["dateUploaded"],
      );

  Map<String, dynamic> toMap() => {
        "chapterUrl": chapterUrl,
        "chapterTitle": chapterTitle,
        "dateUploaded": dateUploaded,
      };
}
