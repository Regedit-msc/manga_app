import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';

class DownloadingState {
  List<Map<String, dynamic>> downloads;
  DownloadingState({this.downloads = const []});
}

class DownloadingCubit extends Cubit<DownloadingState> {
  SharedServiceImpl sharedServiceImpl;
  NavigationServiceImpl navigationServiceImpl;
  DownloadingCubit(
      {required this.sharedServiceImpl, required this.navigationServiceImpl})
      : super(DownloadingState());

  Future<void> pauseChapterDownload({required String chapterUrl}) async {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    List<Map<String, dynamic>> downloadStateForChapter =
        currentlyBeingDownloaded
            .where((element) => element["chapterUrl"] == chapterUrl)
            .toList();
    for (int i = 0; i < downloadStateForChapter.length; i++) {
      if (downloadStateForChapter[i]["status"] == DownloadTaskStatus.running ||
          downloadStateForChapter[i]["status"] == DownloadTaskStatus.running) {
        print("Pausing $i");
        await FlutterDownloader.pause(
            taskId: downloadStateForChapter[i]["taskId"]);
      }
    }
  }

  void setDownload(List<Map<String, dynamic>> downloadList) {
    emit(DownloadingState(downloads: downloadList));
  }

  void addDownload(Map<String, dynamic> downloadList) {
    emit(DownloadingState(downloads: [
      ...state.downloads,
      downloadList,
    ]));
  }

  void changeTaskID(String taskid, String newTaskID) {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    Map<String, dynamic> current = currentlyBeingDownloaded
        .firstWhere((element) => element["taskId"] == taskid, orElse: () => {});
    List<Map<String, dynamic>> withoutCurrent = currentlyBeingDownloaded
        .where((element) => element["taskId"] != taskid)
        .toList();
    current['taskId'] = newTaskID;
    this.setDownload([...withoutCurrent, current]);
  }

  Future<void> resumeChapterDownload({required String chapterUrl}) async {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    List<Map<String, dynamic>> downloadStateForChapter =
        currentlyBeingDownloaded
            .where((element) => element["chapterUrl"] == chapterUrl)
            .toList();
    for (int i = 0; i < downloadStateForChapter.length; i++) {
      if (downloadStateForChapter[i]["status"] == DownloadTaskStatus.paused) {
        String? newTaskId = await FlutterDownloader.resume(
            taskId: downloadStateForChapter[i]["taskId"]);
        if (newTaskId != null) {
          changeTaskID(downloadStateForChapter[i]["taskId"], newTaskId!);
        }
      } else if (downloadStateForChapter[i]["status"] ==
              DownloadTaskStatus.failed ||
          downloadStateForChapter[i]["status"] == DownloadTaskStatus.canceled) {
        String? newTaskId = await FlutterDownloader.retry(
            taskId: downloadStateForChapter[i]["taskId"]);
        if (newTaskId != null) {
          changeTaskID(downloadStateForChapter[i]["taskId"], newTaskId);
        }
      }
    }
  }

  bool isMangaStillDownloading({required mangaUrl}) {
    List<Map<String, dynamic>> downloadList = List.from(state.downloads);
    List<Map<String, dynamic>> mangasForUrl = downloadList
        .where((element) => element["mangaUrl"] == mangaUrl)
        .toList();
    if (mangasForUrl
        .any((element) => element["status"] == DownloadTaskStatus.running)) {
      return true;
    } else if (mangasForUrl
        .any((element) => element["status"] == DownloadTaskStatus.paused)) {
      return true;
    } else if (mangasForUrl
        .any((element) => element["status"] == DownloadTaskStatus.enqueued)) {
      return true;
    } else if (mangasForUrl
        .every((element) => element["status"] == DownloadTaskStatus.complete)) {
      return false;
    }
    return true;
  }
  // void removeDownloaded() {
  //   List<Map<String, dynamic>> downloadList = List.from(state.downloads);
  //   for (int i = 0; i < downloadList.length; i++) {
  //     if (!this
  //         .isMangaStillDownloading(mangaUrl: downloadList[i]["mangaUrl"])) {
  //       ToDownloadQueue thisMangaQueue = state.toDownloadMangaQueue.firstWhere(
  //               (element) => element.mangaUrl == downloadList[i]["mangaUrl"],
  //           orElse: () => ToDownloadQueue(
  //             mangaUrl: '',
  //             mangaName: '',
  //           ));
  //       thisMangaQueue.isDownloading = false;
  //       thisMangaQueue.chaptersToDownload = [];
  //       List<ToDownloadQueue> withoutThisMangaQueue = state.toDownloadMangaQueue
  //           .where((element) => element.mangaUrl != thisMangaQueue.mangaUrl)
  //           .toList();
  //       emit(
  //         ToDownloadState(
  //             toDownloadMangaQueue: [...withoutThisMangaQueue, thisMangaQueue]
  //                 .unique((e) => e.mangaUrl),
  //             downloads: [
  //               ...downloadList
  //                   .where((element) =>
  //               element["mangaUrl"] != downloadList[i]["mangaUrl"])
  //                   .toList()
  //             ]),
  //       );
  //       navigationServiceImpl.navigationKey.currentContext!
  //           .read<DownloadedCubit>()
  //           .refresh();
  //       toastServiceImpl.showToast(
  //           "Successfully downloaded chapters.", Toast.LENGTH_SHORT);
  //     }
  //   }
  // }
}
