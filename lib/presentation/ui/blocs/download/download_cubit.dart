import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webcomic/data/common/extensions/list_extension.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/data/services/api/gql_api.dart';

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
      this.status = DownloadTaskStatus.undefined,
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

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}

class ToDownloadChapter {
  final String chapterName;
  final String chapterUrl;
  final String mangaName;
  final String mangaUrl;
  final String mangaImageUrl;
  ToDownloadChapter(this.mangaImageUrl, this.chapterName, this.chapterUrl,
      this.mangaName, this.mangaUrl);

  factory ToDownloadChapter.fromChapterList(ChapterList chapter,
          String mangaName, String mangaUrl, String imageUrl) =>
      ToDownloadChapter(imageUrl, chapter.chapterTitle, chapter.chapterUrl,
          mangaName, mangaUrl);
}

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

class ToDownloadState {
  List<ToDownloadQueue> toDownloadMangaQueue;
  List<Map<String, dynamic>> downloads;
  ToDownloadState(
      {this.toDownloadMangaQueue = const [], this.downloads = const []});
}

class ToDownloadCubit extends Cubit<ToDownloadState> {
  GQLRawApiServiceImpl gqlRawApiServiceImpl;
  ToDownloadCubit({required this.gqlRawApiServiceImpl})
      : super(ToDownloadState());
  void addAllChaptersToMangaListInQueue(
      {required List<ChapterList> chapters,
      required String mangaName,
      required String mangaUrl,
      required String imageUrl}) {
    List<ToDownloadChapter> mangaChaptersToDownload = chapters
        .map((e) =>
            ToDownloadChapter.fromChapterList(e, mangaName, mangaUrl, imageUrl))
        .toList();

    ToDownloadQueue newQueueForThisManga = ToDownloadQueue(
        mangaUrl: mangaUrl,
        mangaName: mangaName,
        chaptersToDownload:
            mangaChaptersToDownload.unique((e) => e.chapterUrl));
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
  }

  void addRangeIndexForManga(
      {required int index,
      required String mangaUrl,
      required String mangaName}) {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (element) => element.mangaUrl == mangaUrl,
        orElse: () =>
            ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName));
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue newQueueForThisManga = ToDownloadQueue(
        mangaUrl: mangaUrl,
        mangaName: queueForThisManga.mangaName,
        isRangeSelectorEnabled: queueForThisManga.isRangeSelectorEnabled,
        rangeIndexes: [...queueForThisManga.rangeIndexes, index],
        chaptersToDownload: [...queueForThisManga.chaptersToDownload]
            .unique((e) => e.chapterUrl));
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
  }

  void rangeSelectorForManga(
      {required List<ChapterList> chapterList,
      required String mangaName,
      required String mangaUrl,
      required String imageUrl}) {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (element) => element.mangaUrl == mangaUrl,
        orElse: () =>
            ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName));
    print(queueForThisManga.rangeIndexes);
    List<ToDownloadChapter> chaptersToDownload =
        List.from(queueForThisManga.chaptersToDownload);
    print("Chapters to download before ${chaptersToDownload.length}");
    for (int i = queueForThisManga.rangeIndexes[0];
        i < queueForThisManga.rangeIndexes[1] + 1;
        i++) {
      chaptersToDownload.add(ToDownloadChapter.fromChapterList(
          chapterList[i], mangaName, mangaUrl, imageUrl));
    }
    print(
        "Chapters to download after ${chaptersToDownload.unique((e) => e.chapterUrl).length}");
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue newQueueForThisManga = ToDownloadQueue(
        mangaUrl: mangaUrl,
        mangaName: queueForThisManga.mangaName,
        chaptersToDownload:
            [...chaptersToDownload].unique((e) => e.chapterUrl));
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
  }

  String generateDirName(
      String chapterName,
      String chapterUrl,
      // mangaName-chapterNo-mangaUrl-chapterUrl
      String mangaName,
      String mangaUrl) {
    int chapterNo = int.parse(chapterName.replaceAll("-", " ").split(" ")[
        chapterName
                .replaceAll("-", " ")
                .split(" ")
                .indexWhere((element) => element == "chapter") +
            1]);

    return "${mangaName.trim()}-$chapterNo-${mangaUrl.trim()}-${chapterUrl.trim()}";
  }

  Future<void> requestDownload(
      {required imagesLength,
      required String url,
      required String chapterName,
      required String chapterUrl,
      required String mangaUrl,
      required String chapterDirName,
      required String mangaName,
      required String imageName}) async {
    print(url);
    print(chapterName);
    print(chapterDirName);
    print(imageName);
    final dir = await getApplicationDocumentsDirectory();
    var _localPath = dir.path + chapterDirName;
    final savedDir = Directory(_localPath);
    if (await savedDir.exists()) {
      String? taskid = await FlutterDownloader.enqueue(
        url: url,
        fileName: imageName,
        savedDir: _localPath,
        showNotification: false,
        openFileFromNotification: false,
      );
      print(taskid);
      // mangaName-chapterNo-mangaUrl-chapterUrl

      emit(ToDownloadState(
          toDownloadMangaQueue: state.toDownloadMangaQueue,
          downloads: [
            OngoingDownloads(
                    taskId: taskid,
                    mangaUrl: mangaUrl,
                    mangaName: mangaName,
                    imagesLength: imagesLength,
                    chapterUrl: chapterUrl,
                    chapterName: chapterName)
                .toMap(),
            ...state.downloads,
          ]));
      return;
    } else {
      await savedDir.create(recursive: true).then((value) async {
        String? taskid = await FlutterDownloader.enqueue(
          url: url,
          fileName: imageName,
          savedDir: _localPath,
          showNotification: false,
          openFileFromNotification: false,
        );
        emit(ToDownloadState(
            toDownloadMangaQueue: state.toDownloadMangaQueue,
            downloads: [
              OngoingDownloads(
                      taskId: taskid,
                      mangaUrl: mangaUrl,
                      imagesLength: imagesLength,
                      mangaName: mangaName,
                      chapterUrl: chapterUrl,
                      chapterName: chapterName)
                  .toMap(),
              ...state.downloads,
            ]));
      });
      return;
    }
  }

  Future<void> doImageStuffs(
      List<String> images,
      ToDownloadQueue queueForThisManga,
      String mangaUrl,
      String chapterName,
      String chapterUrl,
      String mangaName) async {
    for (int i = 0; i < images.length; i++) {
      print(i);
      await requestDownload(
          mangaUrl: mangaUrl,
          imagesLength: images.length,
          chapterName: chapterName,
          url: images[i],
          chapterDirName:
              '${generateDirName(chapterName, chapterUrl, mangaName, mangaUrl)}',
          imageName: i.toString(),
          chapterUrl: chapterUrl,
          mangaName: mangaName);
    }
  }

  void startDownload({required String mangaUrl}) async {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue
        .firstWhere((element) => element.mangaUrl == mangaUrl);
    ToDownloadQueue newQueueForThisManga = ToDownloadQueue(
        mangaName: queueForThisManga.mangaName,
        mangaUrl: queueForThisManga.mangaUrl,
        isDownloading: true,
        chaptersToDownload: [...queueForThisManga.chaptersToDownload]
            .unique((e) => e.chapterUrl));
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
        toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
            .unique((e) => e.mangaUrl),
        downloads: state.downloads));
    for (int i = 0; i < queueForThisManga.chaptersToDownload.length; i++) {
      GetMangaReaderData? chapterDetails = await gqlRawApiServiceImpl
          .getChapterImages(queueForThisManga.chaptersToDownload[i].chapterUrl);
      if (chapterDetails != null) {
        print("Images length ${chapterDetails.images.length}");
        await this.doImageStuffs(
            chapterDetails.images,
            queueForThisManga,
            mangaUrl,
            queueForThisManga.chaptersToDownload[i].chapterName,
            queueForThisManga.chaptersToDownload[i].chapterUrl,
            queueForThisManga.chaptersToDownload[i].mangaName);
      } else {
        continue;
      }
    }
  }

  void removeAllChaptersFromMangaListInQueue({required String mangaUrl}) {
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue
        .firstWhere((element) => element.mangaUrl == mangaUrl);
    ToDownloadQueue newQueueForManga = ToDownloadQueue(
        mangaName: queueForThisManga.mangaName, mangaUrl: mangaUrl);
    emit(ToDownloadState(
        downloads: state.downloads,
        toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForManga]
            .unique((e) => e.mangaUrl)));
  }

  void removeMangaFromQueue({required String mangaUrl}) {
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue: [...queueWithoutCurrent].unique((e) => e.mangaUrl),
    ));
  }

  void toggleRangeSelectorForManga(
      {required String mangaUrl, required String mangaName}) {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (element) => element.mangaUrl == mangaUrl,
        orElse: () =>
            ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName));
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue newQueueForManga = ToDownloadQueue(
        mangaName: queueForThisManga.mangaName,
        mangaUrl: mangaUrl,
        isRangeSelectorEnabled: !queueForThisManga.isRangeSelectorEnabled,
        chaptersToDownload: queueForThisManga.chaptersToDownload);
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue:
          [...queueWithoutCurrent, newQueueForManga].unique((e) => e.mangaUrl),
    ));
  }

  void removeChapterFromMangaListInQueue(
      {required ToDownloadChapter chapter,
      required String mangaName,
      required String mangaUrl}) {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (element) => element.mangaUrl == mangaUrl,
        orElse: () =>
            ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName));
    List<ToDownloadChapter> chaptersToDownload =
        List.from(queueForThisManga.chaptersToDownload);
    chaptersToDownload
        .removeWhere((element) => element.chapterUrl == chapter.chapterUrl);
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue newQueueForManga = ToDownloadQueue(
        mangaName: mangaName,
        mangaUrl: mangaUrl,
        chaptersToDownload: chaptersToDownload.unique((e) => e.chapterUrl));
    emit(ToDownloadState(
        toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForManga]
            .unique((e) => e.mangaUrl),
        downloads: state.downloads));
  }

  void addChapterToMangaListInQueue(
      {required ToDownloadChapter chapter,
      required String mangaName,
      required String mangaUrl}) {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (element) => element.mangaUrl == mangaUrl,
        orElse: () =>
            ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName));
    List<ToDownloadChapter> chaptersToDownload =
        List.from(queueForThisManga.chaptersToDownload);
    chaptersToDownload.add(chapter);
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    ToDownloadQueue newQueueForManga = ToDownloadQueue(
        mangaName: mangaName,
        mangaUrl: mangaUrl,
        chaptersToDownload: chaptersToDownload.unique((e) => e.chapterUrl));
    emit(ToDownloadState(
      downloads: state.downloads,
      toDownloadMangaQueue:
          [...queueWithoutCurrent, newQueueForManga].unique((e) => e.mangaUrl),
    ));
  }

  void createQueue({required String mangaName, required String mangaUrl}) {
    ToDownloadQueue newQueue =
        ToDownloadQueue(mangaUrl: mangaUrl, mangaName: mangaName);
    emit(ToDownloadState(
        toDownloadMangaQueue:
            [...state.toDownloadMangaQueue, newQueue].unique((e) => e.mangaUrl),
        downloads: state.downloads));
  }

  void reset() {
    emit(ToDownloadState());
  }

  void setDownload(List<Map<String, dynamic>> downloadList) {
    emit(ToDownloadState(
        toDownloadMangaQueue: state.toDownloadMangaQueue,
        downloads: downloadList));
  }

  void makeMangasDoneDownloadingFalse() {
    List<ToDownloadQueue> queuesStillDownloading = List.from(state
        .toDownloadMangaQueue
        .where((element) => element.isDownloading)
        .toList());
    List<ToDownloadQueue> queuesNotDownloading = List.from(state
        .toDownloadMangaQueue
        .where((element) => !element.isDownloading)
        .toList());
    List<Map<String, dynamic>> currentDownloads = state.downloads;
    for (int i = 0; i < queuesStillDownloading.length; i++) {
      List<Map<String, dynamic>> onlyThis = currentDownloads
          .where((element) => element["mangaUrl"] == queuesStillDownloading[i])
          .toList();
      // if (onlyThis.isNotEmpty &&
      //     onlyThis.every((element) => element["progress"] == 100)) {
      //   print("OnlyThis ${onlyThis.length}");
      //   queuesStillDownloading[i].isDownloading = false;
      //   queuesStillDownloading[i].chaptersToDownload = [];
      // }
    }
    emit(ToDownloadState(
        toDownloadMangaQueue: [
          ...queuesStillDownloading,
          ...queuesNotDownloading
        ].unique((e) => e.mangaUrl),
        downloads: state.downloads));
  }
}
