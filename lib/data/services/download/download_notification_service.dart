import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;
import '../../../main.dart';
import 'download_progress_service.dart';

class DownloadNotificationService {
  static const String _channelId = 'manga_downloads';
  static const String _channelName = 'Manga Downloads';
  static const String _channelDescription =
      'Notifications for manga download progress';

  static const int _downloadNotificationId = 1000;
  static const int _completionNotificationId = 2000;

  static final DownloadNotificationService _instance =
      DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              ln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const ln.AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: ln
                  .Importance.low, // Low importance for progress notifications
              enableLights: false,
              enableVibration: false,
              playSound: false,
            ),
          );
    }

    _isInitialized = true;
  }

  /// Show persistent download progress notification
  Future<void> showDownloadProgress(GlobalDownloadProgress progress) async {
    await initialize();

    if (!progress.hasActiveDownloads) {
      await cancelDownloadNotification();
      return;
    }

    final int totalChapters = progress.totalActiveChapters;
    final double overallProgress = progress.overallProgress;
    final String statusText = progress.statusSummary;

    String title = 'Downloading Manga';
    String body = statusText;

    if (totalChapters == 1) {
      final chapter = progress.activeChapters.first;
      title = 'Downloading ${chapter.mangaName}';
      body = '${chapter.chapterName} - ${chapter.progressText}';
      if (chapter.speedText.isNotEmpty) {
        body += ' • ${chapter.speedText}';
      }
      if (chapter.etaText.isNotEmpty) {
        body += ' • ${chapter.etaText}';
      }
    } else if (totalChapters > 1) {
      title = 'Downloading $totalChapters chapters';
      body = '${(overallProgress * 100).toInt()}% complete';
      if (progress.averageSpeed > 0) {
        body += ' • ${progress.averageSpeed.toStringAsFixed(1)} KB/s avg';
      }
    }

    final androidDetails = ln.AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: ln.Importance.low,
      priority: ln.Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: (overallProgress * 100).round(),
      indeterminate: false,
      enableVibration: false,
      playSound: false,
      actions: [
        const ln.AndroidNotificationAction(
          'pause_all',
          'Pause All',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_pause'),
          cancelNotification: false,
        ),
        const ln.AndroidNotificationAction(
          'view_downloads',
          'View Progress',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_download'),
          cancelNotification: false,
        ),
      ],
    );

    final iosDetails = ln.DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final notificationDetails = ln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      _downloadNotificationId,
      title,
      body,
      notificationDetails,
    );
  }

  /// Show download completion notification
  Future<void> showDownloadComplete({
    required String mangaName,
    required int chaptersCount,
    String? mangaImageUrl,
  }) async {
    await initialize();

    String title = 'Download Complete';
    String body = chaptersCount == 1
        ? '$mangaName - 1 chapter downloaded'
        : '$mangaName - $chaptersCount chapters downloaded';

    ln.AndroidNotificationDetails androidDetails;

    if (mangaImageUrl != null && mangaImageUrl.isNotEmpty) {
      try {
        // Try to show big picture notification
        androidDetails = ln.AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: ln.Importance.high,
          priority: ln.Priority.high,
          autoCancel: true,
          enableVibration: true,
          playSound: true,
          styleInformation: const ln.BigTextStyleInformation(
            '',
            contentTitle: 'Download Complete',
            summaryText: 'Tap to view your downloads',
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          ),
          actions: [
            const ln.AndroidNotificationAction(
              'read_manga',
              'Read Now',
              icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_book'),
            ),
            const ln.AndroidNotificationAction(
              'view_downloads',
              'View Downloads',
              icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_download'),
            ),
          ],
        );
      } catch (e) {
        // Fallback to regular notification if image fails
        androidDetails = _getDefaultCompletionNotification();
      }
    } else {
      androidDetails = _getDefaultCompletionNotification();
    }

    final iosDetails = ln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = ln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      _completionNotificationId + mangaName.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'download_complete:$mangaName',
    );
  }

  ln.AndroidNotificationDetails _getDefaultCompletionNotification() {
    return ln.AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: ln.Importance.high,
      priority: ln.Priority.high,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      actions: [
        const ln.AndroidNotificationAction(
          'read_manga',
          'Read Now',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_book'),
        ),
        const ln.AndroidNotificationAction(
          'view_downloads',
          'View Downloads',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_download'),
        ),
      ],
    );
  }

  /// Show download failed notification
  Future<void> showDownloadFailed({
    required String mangaName,
    required String chapterName,
    required String errorMessage,
  }) async {
    await initialize();

    const title = 'Download Failed';
    final body = '$mangaName - $chapterName\n$errorMessage';

    final androidDetails = ln.AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: ln.Importance.high,
      priority: ln.Priority.high,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      actions: [
        const ln.AndroidNotificationAction(
          'retry_download',
          'Retry',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_refresh'),
        ),
        const ln.AndroidNotificationAction(
          'view_downloads',
          'View Downloads',
          icon: ln.DrawableResourceAndroidBitmap('@drawable/ic_download'),
        ),
      ],
    );

    final iosDetails = ln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = ln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      _completionNotificationId + mangaName.hashCode + chapterName.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'download_failed:$mangaName:$chapterName',
    );
  }

  /// Cancel the ongoing download notification
  Future<void> cancelDownloadNotification() async {
    await flutterLocalNotificationsPlugin.cancel(_downloadNotificationId);
  }

  /// Cancel all download-related notifications
  Future<void> cancelAllDownloadNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
