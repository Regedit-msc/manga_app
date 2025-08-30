import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/services/download/download_notification_service.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';
import 'package:webcomic/presentation/widgets/download/download_widgets.dart';
import '../../blocs/download/downloading_cubit.dart';

class DownloadQueuePage extends StatefulWidget {
  const DownloadQueuePage({Key? key}) : super(key: key);

  @override
  State<DownloadQueuePage> createState() => _DownloadQueuePageState();
}

class _DownloadQueuePageState extends State<DownloadQueuePage> {
  final DownloadProgressService _progressService = DownloadProgressService();
  final DownloadNotificationService _notificationService =
      DownloadNotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
        elevation: 0,
        actions: [
          StreamBuilder<GlobalDownloadProgress>(
            stream: _progressService.progressStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.hasActiveDownloads) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleBulkAction(value, snapshot.data!),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'pause_all',
                    child: Row(
                      children: [
                        Icon(Icons.pause),
                        SizedBox(width: 8),
                        Text('Pause All'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'resume_all',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 8),
                        Text('Resume All'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel_all',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancel All', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<GlobalDownloadProgress>(
        stream: _progressService.progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = snapshot.data!;

          if (!progress.hasActiveDownloads) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Overall progress header
              _buildOverallProgress(context, progress),

              // Chapter list
              Expanded(
                child: _buildChapterList(context, progress),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Downloads',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'All downloads are complete!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(
      BuildContext context, GlobalDownloadProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.statusSummary,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress.overallProgress * 100).toInt()}% complete',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (progress.averageSpeed > 0)
                Text(
                  '${progress.averageSpeed.toStringAsFixed(1)} KB/s',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.overallProgress,
            backgroundColor:
                Theme.of(context).colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList(
      BuildContext context, GlobalDownloadProgress progress) {
    final chapters = progress.allChapters;

    // Sort chapters: downloading first, then queued, then others
    chapters.sort((a, b) {
      if (a.status == DownloadStatus.downloading &&
          b.status != DownloadStatus.downloading) return -1;
      if (b.status == DownloadStatus.downloading &&
          a.status != DownloadStatus.downloading) return 1;
      if (a.status == DownloadStatus.queued &&
          b.status != DownloadStatus.queued) return -1;
      if (b.status == DownloadStatus.queued &&
          a.status != DownloadStatus.queued) return 1;
      return a.lastUpdate.compareTo(b.lastUpdate);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return EnhancedChapterProgressCard(
          progress: chapter,
          onPause: () => _pauseChapter(chapter.chapterUrl),
          onResume: () => _resumeChapter(chapter.chapterUrl),
          onCancel: () => _cancelChapter(chapter.chapterUrl),
        );
      },
    );
  }

  void _handleBulkAction(String action, GlobalDownloadProgress progress) {
    switch (action) {
      case 'pause_all':
        _pauseAllDownloads(progress);
        break;
      case 'resume_all':
        _resumeAllDownloads(progress);
        break;
      case 'cancel_all':
        _showCancelAllDialog(progress);
        break;
    }
  }

  void _pauseAllDownloads(GlobalDownloadProgress progress) async {
    final downloadingChapters = progress.downloadingChapters;
    for (final chapter in downloadingChapters) {
      await context.read<DownloadingCubit>().pauseChapterDownload(
            chapterUrl: chapter.chapterUrl,
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paused ${downloadingChapters.length} downloads'),
          action: SnackBarAction(
            label: 'Resume All',
            onPressed: () => _resumeAllDownloads(progress),
          ),
        ),
      );
    }
  }

  void _resumeAllDownloads(GlobalDownloadProgress progress) async {
    final pausedChapters = progress.allChapters
        .where((c) => c.status == DownloadStatus.paused)
        .toList();

    for (final chapter in pausedChapters) {
      await context.read<DownloadingCubit>().resumeChapterDownload(
            chapterUrl: chapter.chapterUrl,
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resumed ${pausedChapters.length} downloads'),
        ),
      );
    }
  }

  void _showCancelAllDialog(GlobalDownloadProgress progress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel All Downloads'),
        content: Text(
          'Are you sure you want to cancel all ${progress.totalActiveChapters} active downloads? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Downloads'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAllDownloads(progress);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel All'),
          ),
        ],
      ),
    );
  }

  void _cancelAllDownloads(GlobalDownloadProgress progress) {
    final activeChapters = progress.activeChapters;
    for (final chapter in activeChapters) {
      _progressService.updateProgress(
        mangaUrl: chapter.mangaUrl,
        chapterUrl: chapter.chapterUrl,
        totalImages: chapter.totalImages,
        completedImages: chapter.completedImages,
        mangaName: chapter.mangaName,
        chapterName: chapter.chapterName,
        status: DownloadStatus.cancelled,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cancelled ${activeChapters.length} downloads'),
        ),
      );
    }
  }

  void _pauseChapter(String chapterUrl) async {
    await context.read<DownloadingCubit>().pauseChapterDownload(
          chapterUrl: chapterUrl,
        );
  }

  void _resumeChapter(String chapterUrl) async {
    await context.read<DownloadingCubit>().resumeChapterDownload(
          chapterUrl: chapterUrl,
        );
  }

  void _cancelChapter(String chapterUrl) {
    // Update the progress service to mark as cancelled
    final currentProgress = _progressService.currentProgress;
    final chapters = currentProgress.allChapters;
    final chapter = chapters.firstWhere((c) => c.chapterUrl == chapterUrl);

    _progressService.updateProgress(
      mangaUrl: chapter.mangaUrl,
      chapterUrl: chapter.chapterUrl,
      totalImages: chapter.totalImages,
      completedImages: chapter.completedImages,
      mangaName: chapter.mangaName,
      chapterName: chapter.chapterName,
      status: DownloadStatus.cancelled,
    );
  }
}
