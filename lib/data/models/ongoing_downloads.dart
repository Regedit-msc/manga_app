import 'package:flutter_downloader/flutter_downloader.dart';

class OngoingDownloads {
  final String chapterName;
  final String mangaName;
  final String mangaUrl;
  final String chapterUrl;
  final String? taskId;
  final int imagesLength;
  int progress;
  DownloadTaskStatus status;
  OngoingDownloads(
      {required this.taskId,
      required this.mangaUrl,
      required this.mangaName,
      required this.chapterUrl,
      required this.chapterName,
      this.status = DownloadTaskStatus.enqueued,
      this.progress = 0,
      this.imagesLength = 0});
  Map<String, dynamic> toMap() => {
        "taskId": taskId,
        "mangaUrl": mangaUrl,
        "mangaName": mangaName,
        "chapterUrl": chapterUrl,
        "status": status,
        "chapterName": chapterName,
        "progress": progress,
        "imagesLength": imagesLength
      };
}
