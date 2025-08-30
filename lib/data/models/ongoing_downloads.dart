import 'package:flutter_downloader/flutter_downloader.dart';

class OngoingDownloads {
  final String chapterName;
  final String mangaName;
  final String mangaUrl;
  final String chapterUrl;
  final String? taskId;
  final int imagesLength;
  // Absolute directory path where this chapter's images are saved
  final String? chapterDirName;
  // Optional cover image url for the manga, used when promoting to downloaded list
  final String? imageUrl;
  // Number of times this individual image download has been retried
  final int retryCount;
  // Maximum number of retries allowed for this individual image download
  final int maxRetries;
  int progress;
  DownloadTaskStatus status;
  OngoingDownloads(
      {required this.taskId,
      required this.mangaUrl,
      required this.mangaName,
      required this.chapterUrl,
      required this.chapterName,
      this.chapterDirName,
      this.imageUrl,
      this.retryCount = 0,
      this.maxRetries = 3,
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
        "imagesLength": imagesLength,
        "chapterDirName": chapterDirName,
        "imageUrl": imageUrl,
        "retryCount": retryCount,
        "maxRetries": maxRetries,
      };
}
