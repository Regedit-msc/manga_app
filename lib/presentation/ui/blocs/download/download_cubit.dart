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
import 'package:webcomic/data/services/debug/debug_logger.dart';

// downloaded list maintenance happens elsewhere after completion

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

  // Mark download session as complete for a manga without clearing selection
  void markDownloadComplete({required String mangaUrl}) {
    final queueForThisManga = state.toDownloadMangaQueue.firstWhere(
        (e) => e.mangaUrl == mangaUrl,
        orElse: () => ToDownloadQueue(mangaUrl: mangaUrl, mangaName: ''));
    final withoutCurrent = state.toDownloadMangaQueue
        .where((e) => e.mangaUrl != mangaUrl)
        .toList();
    final updated = ToDownloadQueue(
      mangaName: queueForThisManga.mangaName,
      mangaUrl: queueForThisManga.mangaUrl,
      isDownloading: false,
      isRangeSelectorEnabled: false,
      rangeIndexes: const [],
      chaptersToDownload:
          [...queueForThisManga.chaptersToDownload].unique((e) => e.chapterUrl),
    );
    emit(ToDownloadState(
      toDownloadMangaQueue:
          [...withoutCurrent, updated].unique((e) => e.mangaUrl),
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
    // Defensive parsing for chapter number (supports integers and decimals like 12.5)
    // Produces directory name pattern: <MangaName>-<chapterNumber>
    String cleanName = mangaName.trim();
    String extractChapterNumber(String s) {
      // Prefer number right after the word 'chapter'
      try {
        final parts = s.replaceAll('-', ' ').split(' ');
        final idx = parts.indexWhere((e) => e.toLowerCase() == 'chapter');
        if (idx != -1 && idx + 1 < parts.length) {
          var next = parts[idx + 1];
          next = next.replaceAll(RegExp(r'[^0-9\._]'), '');
          next = next.replaceAll('_', '.');
          // Validate decimal format
          final dec = RegExp(r'^\d+(?:\.\d+)?$').firstMatch(next)?.group(0);
          if (dec != null) return dec;
        }
      } catch (_) {}
      // Fallback: first occurrence of a number (with optional decimal)
      final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
      return m?.group(1) ?? '';
    }

    final numStr = extractChapterNumber(chapterName);
    if (numStr.isNotEmpty) {
      // Normalize number to avoid trailing .0 in folder name
      final d = double.tryParse(numStr);
      final pretty = d == null
          ? numStr
          : (d % 1 == 0 ? d.toInt().toString() : d.toString());
      return "$cleanName-$pretty";
    }
    // As a last resort, include a short hash of chapterUrl to avoid collisions
    final shortHash = chapterUrl.hashCode.toUnsigned(32).toRadixString(16);
    return "$cleanName-$shortHash";
  }

  // Limit how many images are enqueued at once to avoid overwhelming the queue
  static const int _maxConcurrentEnqueuePerChapter = 3;

  Future<void> requestDownload(
      {required imagesLength,
      required String url,
      required String chapterName,
      required String chapterUrl,
      required String mangaUrl,
      required String chapterDirName,
      required String mangaName,
      required String mangaImageUrl,
      required String imageName}) async {
    DebugLogger.logInfo(
        'enqueue image download: mangaUrl=$mangaUrl chapterUrl=$chapterUrl imageIndex=$imageName',
        category: 'Downloader');
    final dir = await getApplicationDocumentsDirectory();
    var _localPath = dir.path + "/" + chapterDirName;
    final savedDir = Directory(_localPath);
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }

    // Backpressure: if too many tasks enqueued for this chapter already, wait a bit
    final downloadingCubit = navigationServiceImpl.navigationKey.currentContext!
        .read<DownloadingCubit>();
    int attempts = 0;
    while (true) {
      final current = downloadingCubit.state.downloads
          .where((e) => e['chapterUrl'] == chapterUrl)
          .toList();
      final enqueuedOrRunning = current.where((e) {
        final s = e['status'] as DownloadTaskStatus?;
        return s == DownloadTaskStatus.enqueued ||
            s == DownloadTaskStatus.running ||
            s == DownloadTaskStatus.paused;
      }).length;
      if (enqueuedOrRunning < _maxConcurrentEnqueuePerChapter) break;
      if (attempts++ > 50) break; // safety: ~5s max
      await Future.delayed(const Duration(milliseconds: 100));
    }

    String? taskid;
    try {
      // Final existence check just before enqueue to avoid race with cleaners
      if (!await savedDir.exists()) {
        DebugLogger.logInfo(
            'savedDir missing just before enqueue, recreating: $_localPath',
            category: 'Downloader');
        await savedDir.create(recursive: true);
      }
      DebugLogger.logInfo(
          'enqueue -> fileName=${imageName}.jpg dir=$_localPath',
          category: 'Downloader');
      taskid = await FlutterDownloader.enqueue(
        url: url,
        fileName: imageName + ".jpg",
        savedDir: _localPath,
        showNotification: false,
        openFileFromNotification: false,
      );
    } catch (e) {
      // Common in racy cleanup: savedDir assertion; try once more
      try {
        if (!await savedDir.exists()) {
          await savedDir.create(recursive: true);
        }
        DebugLogger.logInfo('enqueue retry after error: $e',
            category: 'Downloader');
        taskid = await FlutterDownloader.enqueue(
          url: url,
          fileName: imageName + ".jpg",
          savedDir: _localPath,
          showNotification: false,
          openFileFromNotification: false,
        );
      } catch (e2) {
        DebugLogger.logInfo('enqueue failed permanently: $e2',
            category: 'Downloader');
        return;
      }
    }
    downloadingCubit.addDownload(OngoingDownloads(
            taskId: taskid,
            mangaUrl: mangaUrl,
            mangaName: mangaName,
            imagesLength: imagesLength,
            chapterUrl: chapterUrl,
            chapterName: chapterName,
            chapterDirName: _localPath,
            imageUrl: mangaImageUrl)
        .toMap());
    return;
  }

  Future<void> doImageStuffs(
      List<String> images,
      ToDownloadQueue queueForThisManga,
      String mangaUrl,
      String chapterName,
      String chapterUrl,
      String mangaName,
      String mangaImageUrl) async {
    // Ensure images are enqueued in order; if any enqueue fails, we'll handle cleanup in the background handler.
    final chapterDirName =
        generateDirName(chapterName, chapterUrl, mangaName, mangaUrl);
    for (int i = 0; i < images.length; i++) {
      // If this chapter has been marked failed/canceled, abort further enqueues
      final ctx = navigationServiceImpl.navigationKey.currentContext;
      if (ctx != null) {
        final downloadingCubit = ctx.read<DownloadingCubit>();
        final chapterTasks = downloadingCubit.state.downloads
            .where((e) => e['chapterUrl'] == chapterUrl)
            .toList();
        final hasTerminalFailure = chapterTasks.any((e) =>
            e['status'] == DownloadTaskStatus.failed ||
            e['status'] == DownloadTaskStatus.canceled);
        if (hasTerminalFailure) {
          DebugLogger.logInfo(
              'abort enqueuing remaining images due to failure/cancel: $chapterUrl',
              category: 'Downloader');
          break;
        }
      }
      DebugLogger.logInfo(
          'enqueue image $i/${images.length - 1} for $chapterUrl',
          category: 'Downloader');
      await requestDownload(
          mangaUrl: mangaUrl,
          imagesLength: images.length,
          chapterName: chapterName,
          url: images[i],
          chapterDirName: chapterDirName,
          imageName: i.toString(),
          chapterUrl: chapterUrl,
          mangaName: mangaName,
          mangaImageUrl: mangaImageUrl);
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

    // Note: adding to downloaded list is handled after confirmation of completion.

    List<ToDownloadQueue> queueWithoutCurrent = state.toDownloadMangaQueue
        .where((element) => element.mangaUrl != mangaUrl)
        .toList();
    emit(ToDownloadState(
      toDownloadMangaQueue: [...queueWithoutCurrent, newQueueForThisManga]
          .unique((e) => e.mangaUrl),
    ));
    for (int i = 0; i < queueForThisManga.chaptersToDownload.length; i++) {
      DebugLogger.logInfo(
          'start chapter download ${i + 1}/${queueForThisManga.chaptersToDownload.length}: ${queueForThisManga.chaptersToDownload[i].chapterUrl}',
          category: 'Downloader');
      GetMangaReaderData? chapterDetails =
          await gqlRawApiServiceImpl.getChapterImages(
              queueForThisManga.chaptersToDownload[i].chapterUrl,
              queueForThisManga.chaptersToDownload[i].mangaSource ?? '');
      if (chapterDetails != null) {
        DebugLogger.logInfo('chapter images: ${chapterDetails.images.length}',
            category: 'Downloader');
        await this.doImageStuffs(
            chapterDetails.images,
            queueForThisManga,
            mangaUrl,
            queueForThisManga.chaptersToDownload[i].chapterName,
            queueForThisManga.chaptersToDownload[i].chapterUrl,
            queueForThisManga.chaptersToDownload[i].mangaName,
            queueForThisManga.chaptersToDownload[i].mangaImageUrl);
      } else {
        DebugLogger.logInfo('failed to fetch images for chapter, skipping',
            category: 'Downloader');
        continue;
      }
    }
    // Defer adding to "downloaded" list until completion is confirmed in DownloadingCubit.
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
