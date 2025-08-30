// To parse this JSON data, do
//
//     final mangaSearchResults = mangaSearchResultsFromMap(jsonString);

import 'dart:convert';

import 'package:webcomic/data/models/newest_manga_model.dart';

MangaSearchResults mangaSearchResultsFromMap(String str) =>
    MangaSearchResults.fromMap(json.decode(str));

String mangaSearchResultsToMap(MangaSearchResults data) =>
    json.encode(data.toMap());

class MangaSearchResults {
  MangaSearchResults({
    required this.data,
  });

  final Data data;

  factory MangaSearchResults.fromMap(Map<String, dynamic> json) =>
      MangaSearchResults(
        data: Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
        "data": data.toMap(),
      };

  @override
  String toString() => 'MangaSearchResults(data: ${data.toString()})';
}

class Data {
  Data({
    required this.mangaSearch,
  });

  final MangaSearch mangaSearch;

  factory Data.fromMap(Map<String, dynamic> json) => Data(
        mangaSearch: MangaSearch.fromMap(json["mangaSearch"]),
      );

  Map<String, dynamic> toMap() => {
        "mangaSearch": mangaSearch.toMap(),
      };

  @override
  String toString() =>
      'MangaSearchResults.Data(mangaSearch: ${mangaSearch.toString()})';
}

class MangaSearch {
  MangaSearch({
    required this.message,
    required this.success,
    required this.data,
  });

  final String message;
  final bool success;
  final List<Datum> data;

  factory MangaSearch.fromMap(Map<String, dynamic> json) => MangaSearch(
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
      'MangaSearch(success: ' +
      success.toString() +
      ', items: ' +
      data.length.toString() +
      ')';
}
