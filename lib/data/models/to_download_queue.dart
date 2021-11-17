import 'package:webcomic/data/models/to_download_chapter.dart';

class ToDownloadQueue {
  String mangaName;
  String mangaUrl;
  bool isDownloading;
  bool isRangeSelectorEnabled;
  List<int> rangeIndexes;
  List<ToDownloadChapter> chaptersToDownload;
  ToDownloadQueue(
      {this.rangeIndexes = const [],
      this.isRangeSelectorEnabled = false,
      this.mangaUrl = '',
      this.isDownloading = false,
      this.mangaName = '',
      this.chaptersToDownload = const []});
}
