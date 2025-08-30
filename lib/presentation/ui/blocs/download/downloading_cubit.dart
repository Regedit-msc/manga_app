import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';

class DownloadingState {
  List<Map<String, dynamic>> downloads;
  DownloadingState({this.downloads = const []});
}

class DownloadingCubit extends Cubit<DownloadingState> {
  SharedServiceImpl sharedServiceImpl;
  NavigationServiceImpl navigationServiceImpl;
  // Access Toast through DI via Navigation context when needed
  DownloadingCubit(
      {required this.sharedServiceImpl, required this.navigationServiceImpl})
      : super(DownloadingState());

  // Broadcast progress to floating UI and manager page
  final DownloadProgressService _progressService = DownloadProgressService();

  // Optional soft cap on total concurrent tasks across app
  static const int _globalMaxConcurrentTasks = 6;

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
    // Avoid duplicate task entries
    final exists = state.downloads.any(
        (e) => e['taskId'] != null && e['taskId'] == downloadList['taskId']);
    if (exists) return;

    // Apply a soft global backpressure: if too many tasks tracked, delay admit
    if (state.downloads.length >= _globalMaxConcurrentTasks) {
      DebugLogger.logInfo(
          'backpressure: too many global tasks, delaying admission',
          category: 'Downloader');
      // This is just a soft cap to prevent state explosion; real backpressure is handled before enqueue.
    }
    emit(DownloadingState(downloads: [
      ...state.downloads,
      downloadList,
    ]));

    // Seed/update the progress service when a new task joins
    _updateProgressFromDownloadList();
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
          changeTaskID(downloadStateForChapter[i]["taskId"], newTaskId);
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

  // Called from BaseView isolate port on every status/progress update
  // We extend it by reacting to terminal states to cleanup or promote
  void onTaskUpdate(String id, DownloadTaskStatus status, int progress) {
    final list = List<Map<String, dynamic>>.from(state.downloads);
    final idx = list.indexWhere((e) => e['taskId'] == id);
    if (idx == -1) return;
    final current = Map<String, dynamic>.from(list[idx]);
    current['status'] = status;
    current['progress'] = progress;
    list[idx] = current;
    setDownload(list);

    // Log progress for debugging
    final chapterUrl = current['chapterUrl'] as String? ?? 'unknown';
    final mangaName = current['mangaName'] as String? ?? 'unknown';

    DebugLogger.logInfo(
        'download progress: $mangaName - progress: $progress%, status: $status, chapterUrl: $chapterUrl',
        category: 'Downloader');

    // Update aggregated chapter progress for floating UI
    _updateProgressFromDownloadList();

    // If an image fails/cancels, attempt a bounded retry before failing the chapter
    if (status == DownloadTaskStatus.failed ||
        status == DownloadTaskStatus.canceled) {
      _handleTaskFailureWithRetry(current);
      return;
    }

    if (status == DownloadTaskStatus.complete) {
      _tryPromoteChapterIfComplete(current);
    }
  }

  // Try retrying a single failed task up to its maxRetries; if exceeded, fail the whole chapter
  void _handleTaskFailureWithRetry(Map<String, dynamic> task) async {
    try {
      final oldTaskId = task['taskId'] as String?;
      final retryCount = (task['retryCount'] as int?) ?? 0;
      final maxRetries = (task['maxRetries'] as int?) ?? 3;
      final chapterUrl = task['chapterUrl'] as String?;
      if (chapterUrl == null) {
        _handleChapterFailure(task);
        return;
      }

      if (retryCount >= maxRetries) {
        DebugLogger.logInfo(
            'max retries reached for task $oldTaskId (chapter: $chapterUrl). Failing chapter.',
            category: 'Downloader');
        _handleChapterFailure(task);
        return;
      }

      // Attempt retry
      DebugLogger.logInfo(
          'retrying task $oldTaskId (attempt ${retryCount + 1}/$maxRetries)',
          category: 'Downloader');
      String? newTaskId;
      try {
        newTaskId = await FlutterDownloader.retry(taskId: oldTaskId ?? '');
      } catch (e) {
        DebugLogger.logInfo('retry error: $e', category: 'Downloader');
      }

      if (newTaskId == null) {
        DebugLogger.logInfo('retry returned null taskId, failing chapter',
            category: 'Downloader');
        _handleChapterFailure(task);
        return;
      }

      // Update the task entry with new id and incremented retry count
      final list = List<Map<String, dynamic>>.from(state.downloads);
      final idx = list.indexWhere((e) => e['taskId'] == oldTaskId);
      if (idx != -1) {
        final updated = Map<String, dynamic>.from(list[idx]);
        updated['taskId'] = newTaskId;
        updated['status'] = DownloadTaskStatus.enqueued;
        // Reset progress to let it start fresh
        updated['progress'] = 0;
        updated['retryCount'] = retryCount + 1;
        list[idx] = updated;
        setDownload(list);
        // Also reflect status as downloading soon for progress service
        _updateProgressFromDownloadList();
      }
    } catch (e) {
      DebugLogger.logInfo('retry handler error: $e', category: 'Downloader');
      _handleChapterFailure(task);
    }
  }

  void _handleChapterFailure(Map<String, dynamic> anyTaskForChapter) async {
    try {
      final chapterUrl = anyTaskForChapter['chapterUrl'] as String?;
      if (chapterUrl == null) return;
      DebugLogger.logInfo('chapter failed, cleaning up files: $chapterUrl',
          category: 'Downloader');

      // Notify progress service about failure
      _updateChapterProgressStatus(chapterUrl, DownloadStatus.failed);

      // Cancel all tasks for this chapter
      final tasksForChapter =
          state.downloads.where((e) => e['chapterUrl'] == chapterUrl).toList();
      for (final t in tasksForChapter) {
        final taskId = t['taskId'] as String?;
        if (taskId != null) {
          try {
            await FlutterDownloader.cancel(taskId: taskId);
          } catch (_) {}
        }
      }

      // Delete local dir
      final dirPath = anyTaskForChapter['chapterDirName'] as String?;
      if (dirPath != null) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }

      // Remove all tasks for this chapter from state
      final remaining =
          state.downloads.where((e) => e['chapterUrl'] != chapterUrl).toList();
      setDownload(remaining);

      // Remove from progress service as well
      _progressService.removeChapter(chapterUrl);
    } catch (e) {
      DebugLogger.logInfo('cleanup error: $e', category: 'Downloader');
    }
  }

  void _tryPromoteChapterIfComplete(
      Map<String, dynamic> anyTaskForChapter) async {
    final chapterUrl = anyTaskForChapter['chapterUrl'] as String?;
    if (chapterUrl == null) return;
    final tasksForChapter =
        state.downloads.where((e) => e['chapterUrl'] == chapterUrl).toList();
    if (tasksForChapter.isEmpty) return;

    // If every task for the chapter is complete, we keep files. If some are not complete, do nothing.
    final allComplete = tasksForChapter
        .every((e) => e['status'] == DownloadTaskStatus.complete);
    if (!allComplete) return;

    // Optional: After chapter completes, we can remove those task entries to prevent memory growth.
    final remaining =
        state.downloads.where((e) => e['chapterUrl'] != chapterUrl).toList();
    setDownload(remaining);

    // If this manga has no more active tasks, promote to downloaded list once per manga.
    final mangaUrl = anyTaskForChapter['mangaUrl'] as String?;
    final mangaName = anyTaskForChapter['mangaName'] as String?;
    final imageUrl = anyTaskForChapter['imageUrl'] as String?;
    if (mangaUrl == null || mangaName == null || imageUrl == null) return;

    // Mark chapter as completed in progress service
    try {
      final totalImages = anyTaskForChapter['imagesLength'] as int? ?? 0;
      _progressService.updateProgress(
        mangaUrl: mangaUrl,
        chapterUrl: chapterUrl,
        totalImages: totalImages,
        completedImages: totalImages,
        mangaName: mangaName,
        chapterName: anyTaskForChapter['chapterName'] as String? ?? '',
        status: DownloadStatus.completed,
      );
    } catch (_) {}

    final stillActiveForManga = state.downloads.any((e) =>
        e['mangaUrl'] == mangaUrl &&
        (e['status'] == DownloadTaskStatus.running ||
            e['status'] == DownloadTaskStatus.enqueued ||
            e['status'] == DownloadTaskStatus.paused));
    if (stillActiveForManga) return;

    // Promote manga into downloaded list
    try {
      final existingRaw = sharedServiceImpl.getDownloadedMangaDetails();
      final entry = DownloadedManga(
          mangaUrl: mangaUrl,
          imageUrl: imageUrl,
          mangaName: mangaName,
          dateDownloaded: DateTime.now().toString());
      if (existingRaw.isNotEmpty) {
        final List<dynamic> parsed = jsonDecode(existingRaw);
        final List<DownloadedManga> list =
            parsed.map((e) => DownloadedManga.fromMap(e)).toList();
        final merged = <DownloadedManga>[...list, entry]
            .fold<List<DownloadedManga>>([], (acc, e) {
          if (acc.indexWhere((x) => x.mangaUrl == e.mangaUrl) == -1) acc.add(e);
          return acc;
        });
        await sharedServiceImpl.addDownloadedMangaDetails(
            jsonEncode(merged.map((e) => e.toMap()).toList()));
      } else {
        await sharedServiceImpl
            .addDownloadedMangaDetails(jsonEncode([entry.toMap()]));
      }
      // Refresh queues and downloaded list in UI and notify via toast
      try {
        final ctx = navigationServiceImpl.navigationKey.currentContext;
        if (ctx != null) {
          ctx.read<ToDownloadCubit>().markDownloadComplete(mangaUrl: mangaUrl);
          ctx.read<DownloadedCubit>().refresh();
          try {
            final toast = getItInstance<ToastServiceImpl>();
            toast.showToast(
                'Download complete for $mangaName', Toast.LENGTH_SHORT);
          } catch (_) {}
        }
      } catch (_) {}
      DebugLogger.logInfo('manga completed: $mangaName',
          category: 'Downloader');
    } catch (e) {
      DebugLogger.logInfo('promote error: $e', category: 'Downloader');
    }
  }

  // Aggregate current tasks into chapter-level progress and publish
  void _updateProgressFromDownloadList() {
    // Group downloads by chapterUrl
    final chapterGroups = <String, List<Map<String, dynamic>>>{};
    for (final d in state.downloads) {
      final chapterUrl = d['chapterUrl'] as String?;
      if (chapterUrl == null) continue;
      (chapterGroups[chapterUrl] ??= []).add(d);
    }

    for (final entry in chapterGroups.entries) {
      final chapterUrl = entry.key;
      final downloads = entry.value;
      if (downloads.isEmpty) continue;

      final first = downloads.first;
      final mangaUrl = first['mangaUrl'] as String? ?? '';
      final mangaName = first['mangaName'] as String? ?? '';
      final chapterName = first['chapterName'] as String? ?? '';
      final totalImages = first['imagesLength'] as int? ?? 0;

      int totalProgress = 0;
      int completedTasks = 0;
      for (final d in downloads) {
        final status = d['status'] as DownloadTaskStatus?;
        final prog = d['progress'] as int? ?? 0;
        if (status == DownloadTaskStatus.complete) {
          completedTasks++;
        } else {
          totalProgress += prog;
        }
      }

      int completedImages;
      if (completedTasks == downloads.length) {
        completedImages = totalImages;
      } else {
        final pct = totalProgress / (downloads.length * 100.0);
        completedImages = (pct * totalImages).round() + completedTasks;
        if (completedImages > totalImages) completedImages = totalImages;
        if (completedImages < 0) completedImages = 0;
      }

      DownloadStatus status = DownloadStatus.queued;
      if (downloads.any((d) => d['status'] == DownloadTaskStatus.running)) {
        status = DownloadStatus.downloading;
      } else if (downloads
          .any((d) => d['status'] == DownloadTaskStatus.paused)) {
        status = DownloadStatus.paused;
      } else if (downloads
          .every((d) => d['status'] == DownloadTaskStatus.complete)) {
        status = DownloadStatus.completed;
      } else if (downloads
          .any((d) => d['status'] == DownloadTaskStatus.failed)) {
        status = DownloadStatus.failed;
      } else if (downloads
          .any((d) => d['status'] == DownloadTaskStatus.canceled)) {
        status = DownloadStatus.cancelled;
      }

      _progressService.updateProgress(
        mangaUrl: mangaUrl,
        chapterUrl: chapterUrl,
        totalImages: totalImages,
        completedImages: completedImages,
        mangaName: mangaName,
        chapterName: chapterName,
        status: status,
      );
    }
  }

  void _updateChapterProgressStatus(String chapterUrl, DownloadStatus status) {
    final downloads =
        state.downloads.where((d) => d['chapterUrl'] == chapterUrl).toList();
    if (downloads.isEmpty) return;

    final first = downloads.first;
    final mangaUrl = first['mangaUrl'] as String? ?? '';
    final mangaName = first['mangaName'] as String? ?? '';
    final chapterName = first['chapterName'] as String? ?? '';
    final totalImages = first['imagesLength'] as int? ?? 0;
    final totalProgress =
        downloads.fold<int>(0, (sum, d) => sum + (d['progress'] as int? ?? 0));
    final completedImages = (totalProgress / 100).round();

    _progressService.updateProgress(
      mangaUrl: mangaUrl,
      chapterUrl: chapterUrl,
      totalImages: totalImages,
      completedImages: completedImages,
      mangaName: mangaName,
      chapterName: chapterName,
      status: status,
    );
  }
}
