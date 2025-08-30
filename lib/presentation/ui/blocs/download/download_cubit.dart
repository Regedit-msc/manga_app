import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webcomic/data/common/extensions/list_extension.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/data/models/ongoing_downloads.dart';
import 'package:webcomic/data/models/to_download_chapter.dart';
import 'package:webcomic/data/models/to_download_queue.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';

import 'downloaded_cubit.dart';

class ToDownloadState {
  List<ToDownloadQueue> toDownloadMangaQueue;
  ToDownloadState({this.toDownloadMangaQueue = const []});
}

class ToDownloadCubit extends Cubit<ToDownloadState> {
  GQLRawApiServiceImpl gqlRawApiServiceImpl;
  ToastServiceImpl toastServiceImpl;
  SharedServiceImpl sharedServiceImpl;
  NavigationServiceImpl navigationServiceImpl;
  ToDownloadCubit(
      {required this.gqlRawApiServiceImpl,
      required this.sharedServiceImpl,
      required this.toastServiceImpl,
      required this.navigationServiceImpl})
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
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
  }

  String generateDirName(
      String chapterName,
      String chapterUrl,
      // mangaName-chapterNo
      String mangaName,
      String mangaUrl) {
    int chapterNo = int.parse(chapterName.replaceAll("-", " ").split(" ")[
        chapterName
                .replaceAll("-", " ")
                .split(" ")
                .indexWhere((element) => element == "chapter") +
            1]);

    return "${mangaName.trim()}-$chapterNo";
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
    var _localPath = dir.path + "/" + chapterDirName;
    final savedDir = Directory(_localPath);
    if (await savedDir.exists()) {
      String? taskid = await FlutterDownloader.enqueue(
        url: url,
        fileName: imageName + ".jpg",
        savedDir: _localPath,
        showNotification: false,
        openFileFromNotification: false,
      );

      navigationServiceImpl.navigationKey.currentContext!
          .read<DownloadingCubit>()
          .addDownload(OngoingDownloads(
                  taskId: taskid,
                  mangaUrl: mangaUrl,
                  mangaName: mangaName,
                  imagesLength: imagesLength,
                  chapterUrl: chapterUrl,
                  chapterName: chapterName)
              .toMap());
      // emit(ToDownloadState(
      //     toDownloadMangaQueue: state.toDownloadMangaQueue,
      //     downloads: [
      //       OngoingDownloads(
      //               taskId: taskid,
      //               mangaUrl: mangaUrl,
      //               mangaName: mangaName,
      //               imagesLength: imagesLength,
      //               chapterUrl: chapterUrl,
      //               chapterName: chapterName)
      //           .toMap(),
      //       ...state.downloads,
      //     ]));
      return;
    } else {
      await savedDir.create(recursive: true).then((value) async {
        String? taskid = await FlutterDownloader.enqueue(
          url: url,
          fileName: imageName + ".jpg",
          savedDir: _localPath,
          showNotification: false,
          openFileFromNotification: false,
        );
        navigationServiceImpl.navigationKey.currentContext!
            .read<DownloadingCubit>()
            .addDownload(OngoingDownloads(
                    taskId: taskid,
                    mangaUrl: mangaUrl,
                    mangaName: mangaName,
                    imagesLength: imagesLength,
                    chapterUrl: chapterUrl,
                    chapterName: chapterName)
                .toMap());
        // emit(ToDownloadState(
        //     toDownloadMangaQueue: state.toDownloadMangaQueue,
        //     downloads: [
        //       OngoingDownloads(
        //               taskId: taskid,
        //               mangaUrl: mangaUrl,
        //               imagesLength: imagesLength,
        //               mangaName: mangaName,
        //               chapterUrl: chapterUrl,
        //               chapterName: chapterName)
        //           .toMap(),
        //       ...state.downloads,
        //     ]));
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

  void startDownload(
      {required String mangaUrl,
      required String imageUrl,
      required String mangaName}) async {
    ToDownloadQueue queueForThisManga = state.toDownloadMangaQueue
        .firstWhere((element) => element.mangaUrl == mangaUrl);
    ToDownloadQueue newQueueForThisManga = ToDownloadQueue(
        mangaName: queueForThisManga.mangaName,
        mangaUrl: queueForThisManga.mangaUrl,
        isDownloading: true,
        chaptersToDownload: [...queueForThisManga.chaptersToDownload]
            .unique((e) => e.chapterUrl));

    String listOfDownloads = sharedServiceImpl.getDownloadedMangaDetails();

    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
    for (int i = 0; i < queueForThisManga.chaptersToDownload.length; i++) {
      GetMangaReaderData? chapterDetails =
          await gqlRawApiServiceImpl.getChapterImages(
              queueForThisManga.chaptersToDownload[i].chapterUrl,
              queueForThisManga.chaptersToDownload[i].mangaSource ?? '');
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

    if (listOfDownloads != '') {
      List<dynamic> details = jsonDecode(listOfDownloads);
      List<DownloadedManga> downloadedManga =
          details.map((e) => DownloadedManga.fromMap(e)).toList();
      DownloadedManga mangaToAdd = DownloadedManga(
          mangaUrl: mangaUrl,
          imageUrl: imageUrl,
          mangaName: mangaName,
          dateDownloaded: DateTime.now().toString());
      List<Map<String, dynamic>> newDetails = [...downloadedManga, mangaToAdd]
          .unique((e) => e.mangaUrl)
          .map((e) => e.toMap())
          .toList();
      await sharedServiceImpl.addDownloadedMangaDetails(jsonEncode(newDetails));
    } else {
      DownloadedManga mangaToAdd = DownloadedManga(
          mangaUrl: mangaUrl,
          imageUrl: imageUrl,
          mangaName: mangaName,
          dateDownloaded: DateTime.now().toString());
      Map<String, dynamic> newManga = mangaToAdd.toMap();
      List<Map<String, dynamic>> toEncode = List.from([newManga]);
      String jsonL = jsonEncode(toEncode);
      await sharedServiceImpl.addDownloadedMangaDetails(jsonL);
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
        toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForManga]
            .unique((e) => e.mangaUrl)));
  }

  void removeMangaFromQueue({required String mangaUrl}) {
    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
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
      toDownloadMangaQueue:
          [...queueWithoutCurrent, newQueueForManga].unique((e) => e.mangaUrl),
    ));
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
    ));
  }

  void reset() {
    emit(ToDownloadState());
  }
  // void makeMangasDoneDownloadingFalse() {
  //   List<ToDownloadQueue> queuesStillDownloading = List.from(state
  //       .toDownloadMangaQueue
  //       .where((element) => element.isDownloading)
  //       .toList());
  //   List<ToDownloadQueue> queuesNotDownloading = List.from(state
  //       .toDownloadMangaQueue
  //       .where((element) => !element.isDownloading)
  //       .toList());
  //   List<Map<String, dynamic>> currentDownloads = state.downloads;
  //   for (int i = 0; i < queuesStillDownloading.length; i++) {
  //     List<Map<String, dynamic>> onlyThis = currentDownloads
  //         .where((element) => element["mangaUrl"] == queuesStillDownloading[i])
  //         .toList();
  //     // if (onlyThis.isNotEmpty &&
  //     //     onlyThis.every((element) => element["progress"] == 100)) {
  //     //   print("OnlyThis ${onlyThis.length}");
  //     //   queuesStillDownloading[i].isDownloading = false;
  //     //   queuesStillDownloading[i].chaptersToDownload = [];
  //     // }
  //   }
  //   emit(ToDownloadState(
  //       toDownloadMangaQueue: [
  //         ...queuesStillDownloading,
  //         ...queuesNotDownloading
  //       ].unique((e) => e.mangaUrl),
  //       downloads: state.downloads));
  // }
}
