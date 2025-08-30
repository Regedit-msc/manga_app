import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import "package:path_provider/path_provider.dart";
import 'package:flutter_downloader/flutter_downloader.dart' as fd;
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

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
      DebugLogger.logInfo(
          'refresh downloaded list: count=${downloadedManga.length}',
          category: 'Downloader');
      emit(DownloadedState(downloadedManga: downloadedManga));
    }
  }

  Future<String> getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Delete a specific chapter for a manga
  Future<bool> deleteChapter({
    required String mangaName,
    required String chapterDir,
  }) async {
    try {
      final dir = Directory(chapterDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        DebugLogger.logInfo('deleted chapter directory: $chapterDir',
            category: 'Downloader');
      }

      // Remove the download task from flutter_downloader database
      final tasks = await fd.FlutterDownloader.loadTasksWithRawQuery(
          query: 'SELECT * FROM task WHERE saved_dir = "$chapterDir"');
      if (tasks != null && tasks.isNotEmpty) {
        for (final task in tasks) {
          await fd.FlutterDownloader.remove(
            taskId: task.taskId,
            shouldDeleteContent: false, // We already deleted the directory
          );
        }
      }

      DebugLogger.logInfo('deleted chapter: $chapterDir',
          category: 'Downloader');
      return true;
    } catch (e) {
      DebugLogger.logInfo('failed to delete chapter: $e',
          category: 'Downloader');
      return false;
    }
  }

  /// Delete all chapters for a manga
  Future<bool> deleteManga({
    required String mangaName,
    required String mangaUrl,
  }) async {
    try {
      // Get all tasks for this manga
      final tasks = await fd.FlutterDownloader.loadTasksWithRawQuery(
          query:
              'SELECT * FROM task WHERE saved_dir LIKE "%$mangaName%" AND status=3');

      if (tasks != null && tasks.isNotEmpty) {
        for (final task in tasks) {
          // Delete directory
          final dir = Directory(task.savedDir);
          if (await dir.exists()) {
            await dir.delete(recursive: true);
          }

          // Remove from flutter_downloader database
          await fd.FlutterDownloader.remove(
            taskId: task.taskId,
            shouldDeleteContent: false,
          );
        }
      }

      // Remove from downloaded manga list
      final downloads = sharedServiceImpl.getDownloadedMangaDetails();
      if (downloads.isNotEmpty) {
        final List<dynamic> parsed = jsonDecode(downloads);
        final List<DownloadedManga> list =
            parsed.map((e) => DownloadedManga.fromMap(e)).toList();

        // Remove the manga from the list
        list.removeWhere((manga) => manga.mangaUrl == mangaUrl);

        // Save updated list
        await sharedServiceImpl.addDownloadedMangaDetails(
            jsonEncode(list.map((e) => e.toMap()).toList()));
      }

      // Refresh the UI state
      refresh();

      DebugLogger.logInfo('deleted manga: $mangaName', category: 'Downloader');
      return true;
    } catch (e) {
      DebugLogger.logInfo('failed to delete manga: $e', category: 'Downloader');
      return false;
    }
  }

  /// Get storage information for downloaded content
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      int totalSize = 0;
      int chapterCount = 0;

      final tasks = await fd.FlutterDownloader.loadTasksWithRawQuery(
          query: 'SELECT * FROM task WHERE status=3');

      if (tasks != null) {
        final Map<String, fd.DownloadTask> uniqueDirs = {};
        for (final task in tasks) {
          uniqueDirs[task.savedDir] = task;
        }

        chapterCount = uniqueDirs.length;

        for (final task in uniqueDirs.values) {
          final directory = Directory(task.savedDir);
          if (await directory.exists()) {
            final files = await directory.list(recursive: true).toList();
            for (final file in files) {
              if (file is File) {
                final stat = await file.stat();
                totalSize += stat.size;
              }
            }
          }
        }
      }

      return {
        'totalSize': totalSize,
        'chapterCount': chapterCount,
        'formattedSize': _formatBytes(totalSize),
      };
    } catch (e) {
      DebugLogger.logInfo('failed to get storage info: $e',
          category: 'Downloader');
      return {
        'totalSize': 0,
        'chapterCount': 0,
        'formattedSize': '0 B',
      };
    }
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';

    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
