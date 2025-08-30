import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:webcomic/data/services/download/download_notification_service.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';

class EnhancedDownloadingCubit extends Cubit<DownloadingState> {
  final SharedServiceImpl sharedServiceImpl;
  final NavigationServiceImpl navigationServiceImpl;
  final DownloadProgressService _progressService = DownloadProgressService();
  final DownloadNotificationService _notificationService =
      DownloadNotificationService();

  // Speed tracking for ETA calculation
  final Map<String, List<double>> _chapterSpeeds = {};
  final Map<String, DateTime> _chapterStartTimes = {};

  EnhancedDownloadingCubit(
      {required this.sharedServiceImpl, required this.navigationServiceImpl})
      : super(DownloadingState()) {
    _initializeNotifications();
    _listenToProgressUpdates();
  }

  void _initializeNotifications() async {
    await _notificationService.initialize();
  }

  void _listenToProgressUpdates() {
    _progressService.progressStream.listen((progress) {
      if (progress.hasActiveDownloads) {
        _notificationService.showDownloadProgress(progress);
      }
    });
  }

  static const int _globalMaxConcurrentTasks = 6;

  Future<void> pauseChapterDownload({required String chapterUrl}) async {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    List<Map<String, dynamic>> downloadStateForChapter =
        currentlyBeingDownloaded
            .where((element) => element["chapterUrl"] == chapterUrl)
            .toList();

    for (int i = 0; i < downloadStateForChapter.length; i++) {
      if (downloadStateForChapter[i]["status"] == DownloadTaskStatus.running) {
        await FlutterDownloader.pause(
            taskId: downloadStateForChapter[i]["taskId"]);
      }
    }

    // Update progress service
    _updateChapterProgressStatus(chapterUrl, DownloadStatus.paused);
  }

  Future<void> resumeChapterDownload({required String chapterUrl}) async {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    List<Map<String, dynamic>> downloadStateForChapter =
        currentlyBeingDownloaded
            .where((element) => element["chapterUrl"] == chapterUrl)
            .toList();

    for (int i = 0; i < downloadStateForChapter.length; i++) {
      if (downloadStateForChapter[i]["status"] == DownloadTaskStatus.paused) {
        await FlutterDownloader.resume(
            taskId: downloadStateForChapter[i]["taskId"]);
      }
    }

    // Update progress service
    _updateChapterProgressStatus(chapterUrl, DownloadStatus.downloading);
  }

  void setDownload(List<Map<String, dynamic>> downloadList) {
    emit(DownloadingState(downloads: downloadList));
  }

  void addDownload(Map<String, dynamic> downloadList) {
    // Avoid duplicate task entries
    final exists = state.downloads.any(
        (e) => e['taskId'] != null && e['taskId'] == downloadList['taskId']);
    if (exists) return;

    // Apply a soft global backpressure
    if (state.downloads.length >= _globalMaxConcurrentTasks) {
      DebugLogger.logInfo(
          'backpressure: too many global tasks, delaying admission',
          category: 'Downloader');
    }

    emit(DownloadingState(downloads: [
      ...state.downloads,
      downloadList,
    ]));

    // Initialize chapter progress tracking
    final chapterUrl = downloadList['chapterUrl'] as String?;
    if (chapterUrl != null) {
      _chapterStartTimes[chapterUrl] = DateTime.now();
      _updateProgressFromDownloadList();
    }
  }

  void changeTaskID(String taskid, String newTaskID) {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    Map<String, dynamic> current = currentlyBeingDownloaded
        .firstWhere((element) => element["taskId"] == taskid, orElse: () => {});
    if (current.isNotEmpty) {
      current["taskId"] = newTaskID;
      emit(DownloadingState(downloads: [...currentlyBeingDownloaded]));
    }
  }

  Future<void> retryFailedDownload({required String chapterUrl}) async {
    List<Map<String, dynamic>> currentlyBeingDownloaded = state.downloads;
    List<Map<String, dynamic>> downloadStateForChapter =
        currentlyBeingDownloaded
            .where((element) => element["chapterUrl"] == chapterUrl)
            .toList();

    for (int i = 0; i < downloadStateForChapter.length; i++) {
      if (downloadStateForChapter[i]["status"] == DownloadTaskStatus.failed ||
          downloadStateForChapter[i]["status"] == DownloadTaskStatus.canceled) {
        String? newTaskId = await FlutterDownloader.retry(
            taskId: downloadStateForChapter[i]["taskId"]);
        if (newTaskId != null) {
          changeTaskID(downloadStateForChapter[i]["taskId"], newTaskId);
        }
      }
    }

    // Update progress service
    _updateChapterProgressStatus(chapterUrl, DownloadStatus.downloading);
  }

  // Enhanced task update with speed tracking
  void onTaskUpdate(String id, DownloadTaskStatus status, int progress) {
    final list = List<Map<String, dynamic>>.from(state.downloads);
    final idx = list.indexWhere((e) => e['taskId'] == id);
    if (idx == -1) return;

    final current = Map<String, dynamic>.from(list[idx]);
    final previousProgress = current['progress'] as int? ?? 0;
    current['status'] = status;
    current['progress'] = progress;
    list[idx] = current;
    setDownload(list);

    // Track download speed
    final chapterUrl = current['chapterUrl'] as String?;
    if (chapterUrl != null) {
      _trackDownloadSpeed(chapterUrl, progress, previousProgress);
    }

    // Update progress service with detailed information immediately
    _updateProgressFromDownloadList();

    // Handle terminal states
    if (status == DownloadTaskStatus.failed ||
        status == DownloadTaskStatus.canceled) {
      _handleChapterFailure(current);
      return;
    }

    if (status == DownloadTaskStatus.complete) {
      // Wait a brief moment to ensure all concurrent tasks finish
      Future.delayed(const Duration(milliseconds: 100), () {
        _tryPromoteChapterIfComplete(current);
      });
    }
  }

  void _trackDownloadSpeed(
      String chapterUrl, int currentProgress, int previousProgress) {
    if (currentProgress <= previousProgress) return;

    final now = DateTime.now();
    final startTime = _chapterStartTimes[chapterUrl];
    if (startTime == null) return;

    final elapsedSeconds = now.difference(startTime).inSeconds;
    if (elapsedSeconds == 0) return;

    // Calculate speed in KB/s (rough estimate based on typical manga image sizes)
    final progressDiff = currentProgress - previousProgress;
    final estimatedKB =
        progressDiff * 0.5; // Rough estimate: 0.5KB per progress point
    final speedKbps = estimatedKB / 1; // Per second

    // Track recent speeds for smoothing
    _chapterSpeeds[chapterUrl] = _chapterSpeeds[chapterUrl] ?? [];
    _chapterSpeeds[chapterUrl]!.add(speedKbps);

    // Keep only last 10 speed measurements
    if (_chapterSpeeds[chapterUrl]!.length > 10) {
      _chapterSpeeds[chapterUrl]!.removeAt(0);
    }
  }

  double _getAverageSpeed(String chapterUrl) {
    final speeds = _chapterSpeeds[chapterUrl];
    if (speeds == null || speeds.isEmpty) return 0.0;
    return speeds.reduce((a, b) => a + b) / speeds.length;
  }

  Duration? _calculateETA(
      String chapterUrl, int totalImages, int completedImages) {
    final remainingImages = totalImages - completedImages;
    if (remainingImages <= 0) return null;

    final avgSpeed = _getAverageSpeed(chapterUrl);
    if (avgSpeed <= 0) return null;

    // Rough estimate: each image takes 1/speed seconds
    final estimatedSeconds = (remainingImages / avgSpeed).round();
    return Duration(seconds: estimatedSeconds.clamp(0, 3600)); // Cap at 1 hour
  }

  void _updateProgressFromDownloadList() {
    // Group downloads by chapter
    final chapterGroups = <String, List<Map<String, dynamic>>>{};
    for (final download in state.downloads) {
      final chapterUrl = download['chapterUrl'] as String?;
      if (chapterUrl != null) {
        chapterGroups[chapterUrl] = chapterGroups[chapterUrl] ?? [];
        chapterGroups[chapterUrl]!.add(download);
      }
    }

    // Update progress for each chapter
    for (final entry in chapterGroups.entries) {
      final chapterUrl = entry.key;
      final downloads = entry.value;

      if (downloads.isEmpty) continue;

      final firstDownload = downloads.first;
      final mangaUrl = firstDownload['mangaUrl'] as String? ?? '';
      final mangaName = firstDownload['mangaName'] as String? ?? '';
      final chapterName = firstDownload['chapterName'] as String? ?? '';
      final totalImages = firstDownload['imagesLength'] as int? ?? 0;

      // Calculate progress and status - fix progress calculation
      int totalProgress = 0;
      int completedTasks = 0;
      for (final d in downloads) {
        final progress = d['progress'] as int? ?? 0;
        final status = d['status'] as DownloadTaskStatus?;

        if (status == DownloadTaskStatus.complete) {
          completedTasks++;
        } else {
          totalProgress += progress;
        }
      }

      // More accurate completed images calculation
      int completedImages;
      if (completedTasks == downloads.length) {
        // All tasks complete
        completedImages = totalImages;
      } else {
        // Calculate based on progress and completed tasks
        final progressPercentage = totalProgress / (downloads.length * 100.0);
        completedImages =
            (progressPercentage * totalImages).round() + completedTasks;
        completedImages = completedImages.clamp(0, totalImages);
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

      // Calculate speed and ETA
      final avgSpeed = _getAverageSpeed(chapterUrl);
      final eta = status == DownloadStatus.downloading
          ? _calculateETA(chapterUrl, totalImages, completedImages)
          : null;

      _progressService.updateProgress(
        mangaUrl: mangaUrl,
        chapterUrl: chapterUrl,
        totalImages: totalImages,
        completedImages: completedImages,
        mangaName: mangaName,
        chapterName: chapterName,
        status: status,
        speedKbps: avgSpeed > 0 ? avgSpeed : null,
        eta: eta,
      );
    }
  }

  void _updateChapterProgressStatus(String chapterUrl, DownloadStatus status) {
    final downloads =
        state.downloads.where((d) => d['chapterUrl'] == chapterUrl).toList();
    if (downloads.isEmpty) return;

    final firstDownload = downloads.first;
    final mangaUrl = firstDownload['mangaUrl'] as String? ?? '';
    final mangaName = firstDownload['mangaName'] as String? ?? '';
    final chapterName = firstDownload['chapterName'] as String? ?? '';
    final totalImages = firstDownload['imagesLength'] as int? ?? 0;
    final totalProgress =
        downloads.fold(0, (sum, d) => sum + (d['progress'] as int? ?? 0));
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

  void _handleChapterFailure(Map<String, dynamic> anyTaskForChapter) async {
    try {
      final chapterUrl = anyTaskForChapter['chapterUrl'] as String?;
      final chapterName = anyTaskForChapter['chapterName'] as String? ?? '';
      final mangaName = anyTaskForChapter['mangaName'] as String? ?? '';

      if (chapterUrl == null) return;

      DebugLogger.logInfo('chapter failed, cleaning up files: $chapterUrl',
          category: 'Downloader');

      // Update progress service
      _updateChapterProgressStatus(chapterUrl, DownloadStatus.failed);

      // Show failure notification
      await _notificationService.showDownloadFailed(
        mangaName: mangaName,
        chapterName: chapterName,
        errorMessage: 'Download failed due to network or server error',
      );

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

      // Clean up tracking data
      _chapterSpeeds.remove(chapterUrl);
      _chapterStartTimes.remove(chapterUrl);
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

    // If every task for the chapter is complete, promote to completed
    final allComplete = tasksForChapter
        .every((e) => e['status'] == DownloadTaskStatus.complete);
    if (!allComplete) {
      // Update progress for partially complete chapter
      _updateProgressFromDownloadList();
      return;
    }

    // Update progress service with complete status
    final firstTask = tasksForChapter.first;
    final mangaUrl = firstTask['mangaUrl'] as String? ?? '';
    final mangaName = firstTask['mangaName'] as String? ?? '';
    final chapterName = firstTask['chapterName'] as String? ?? '';
    final totalImages = firstTask['imagesLength'] as int? ?? 0;

    _progressService.updateProgress(
      mangaUrl: mangaUrl,
      chapterUrl: chapterUrl,
      totalImages: totalImages,
      completedImages: totalImages, // Mark as fully complete
      mangaName: mangaName,
      chapterName: chapterName,
      status: DownloadStatus.completed,
    );

    // Clean up tracking data
    _chapterSpeeds.remove(chapterUrl);
    _chapterStartTimes.remove(chapterUrl);

    // Remove completed tasks from state
    final remaining =
        state.downloads.where((e) => e['chapterUrl'] != chapterUrl).toList();
    setDownload(remaining);

    // Check if manga is complete
    final imageUrl = anyTaskForChapter['imageUrl'] as String?;

    if (mangaUrl.isEmpty || mangaName.isEmpty || imageUrl == null) return;

    final stillActiveForManga = state.downloads.any((e) =>
        e['mangaUrl'] == mangaUrl &&
        (e['status'] == DownloadTaskStatus.running ||
            e['status'] == DownloadTaskStatus.enqueued ||
            e['status'] == DownloadTaskStatus.paused));

    if (stillActiveForManga) {
      // Continue tracking progress for remaining chapters
      _updateProgressFromDownloadList();
      return;
    }

    // Remove completed chapter from progress tracking
    _progressService.removeChapter(chapterUrl);

    // Promote manga to downloaded list
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

      // Show completion notification
      final completedChapterCount = _progressService.currentProgress.allChapters
          .where((c) =>
              c.mangaUrl == mangaUrl && c.status == DownloadStatus.completed)
          .length;

      await _notificationService.showDownloadComplete(
        mangaName: mangaName,
        chaptersCount: completedChapterCount,
        mangaImageUrl: imageUrl,
      );

      // Refresh UI
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

  @override
  Future<void> close() {
    _progressService.dispose();
    return super.close();
  }
}
