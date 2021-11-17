import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import "package:path_provider/path_provider.dart";
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';

class DownloadedManga {
  final String mangaUrl;
  final String imageUrl;
  final String mangaName;
  final String dateDownloaded;
  DownloadedManga(
      {required this.mangaUrl,
      required this.imageUrl,
      required this.mangaName,
      required this.dateDownloaded});
  factory DownloadedManga.fromMap(Map<String, dynamic> json) => DownloadedManga(
      mangaUrl: json['mangaUrl'],
      imageUrl: json['imageUrl'],
      mangaName: json['mangaName'],
      dateDownloaded: json["dateDownloaded"]);
  Map<String, dynamic> toMap() => {
        "mangaUrl": mangaUrl,
        "imageUrl": imageUrl,
        "mangaName": mangaName,
        "dateDownloaded": dateDownloaded
      };
}

class DownloadedState {
  List<DownloadedManga> downloadedManga;
  DownloadedState({this.downloadedManga = const []});
}

class DownloadedCubit extends Cubit<DownloadedState> {
  SharedServiceImpl sharedServiceImpl;
  NavigationServiceImpl navigationServiceImpl;
  DownloadedCubit(
      {required this.sharedServiceImpl, required this.navigationServiceImpl})
      : super(DownloadedState());

  void refresh() {
    String downloads = sharedServiceImpl.getDownloadedMangaDetails();
    if (downloads != '') {
      List<dynamic> details = jsonDecode(downloads);
      List<DownloadedManga> downloadedManga =
          details.map((e) => DownloadedManga.fromMap(e)).toList();
      emit(DownloadedState(downloadedManga: downloadedManga));
    }
  }

  Future<String> getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}
