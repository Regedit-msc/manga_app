import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';
import 'package:webcomic/presentation/widgets/download/download_widgets.dart';

class EnhancedDownloadQueueWidget extends StatefulWidget {
  const EnhancedDownloadQueueWidget({Key? key}) : super(key: key);

  @override
  State<EnhancedDownloadQueueWidget> createState() =>
      _EnhancedDownloadQueueWidgetState();
}

class _EnhancedDownloadQueueWidgetState
    extends State<EnhancedDownloadQueueWidget> {
  final DownloadProgressService _progressService = DownloadProgressService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalDownloadProgress>(
      stream: _progressService.progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;

        if (!progress.hasActiveDownloads) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Overall progress summary
              _buildOverallProgressCard(context, progress),

              const SizedBox(height: 8),

              // Active downloads list
              if (progress.hasActiveDownloads)
                ...progress.activeChapters.map(
                  (chapter) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: EnhancedChapterProgressCard(
                      progress: chapter,
                      onPause: () => _pauseChapter(chapter.chapterUrl),
                      onResume: () => _resumeChapter(chapter.chapterUrl),
                      onCancel: () => _cancelChapter(chapter.chapterUrl),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallProgressCard(
      BuildContext context, GlobalDownloadProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download Queue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (progress.hasActiveDownloads)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleBulkAction(value, progress),
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
                            Text('Cancel All',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Overall progress bar
            LinearProgressIndicator(
              value: progress.overallProgress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // Progress details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.statusSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (progress.averageSpeed > 0)
                  Text(
                    '${progress.averageSpeed.toStringAsFixed(1)} KB/s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
        _showCancelAllConfirmation(progress);
        break;
    }
  }

  void _pauseAllDownloads(GlobalDownloadProgress progress) {
    final activeChapters = progress.activeChapters;
    for (final chapter in activeChapters) {
      if (chapter.status == DownloadStatus.downloading) {
        _pauseChapter(chapter.chapterUrl);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paused ${activeChapters.length} downloads'),
      ),
    );
  }

  void _resumeAllDownloads(GlobalDownloadProgress progress) {
    final pausedChapters = progress.allChapters
        .where((c) => c.status == DownloadStatus.paused)
        .toList();

    for (final chapter in pausedChapters) {
      _resumeChapter(chapter.chapterUrl);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resumed ${pausedChapters.length} downloads'),
      ),
    );
  }

  void _showCancelAllConfirmation(GlobalDownloadProgress progress) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel All Downloads'),
          content: Text(
            'Are you sure you want to cancel all ${progress.activeChapters.length} active downloads? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Downloading'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelAllDownloads(progress);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel All'),
            ),
          ],
        );
      },
    );
  }

  void _cancelAllDownloads(GlobalDownloadProgress progress) {
    final activeChapters = progress.activeChapters;
    for (final chapter in activeChapters) {
      _cancelChapter(chapter.chapterUrl);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cancelled ${activeChapters.length} downloads'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _pauseChapter(String chapterUrl) async {
    try {
      await context.read<DownloadingCubit>().pauseChapterDownload(
            chapterUrl: chapterUrl,
          );
    } catch (e) {
      // Handle error silently or show a toast
    }
  }

  void _resumeChapter(String chapterUrl) async {
    try {
      await context.read<DownloadingCubit>().resumeChapterDownload(
            chapterUrl: chapterUrl,
          );
    } catch (e) {
      // Handle error silently or show a toast
    }
  }

  void _cancelChapter(String chapterUrl) {
    try {
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
    } catch (e) {
      // Handle error silently
    }
  }
}

/// Floating mini download progress widget
class MiniDownloadProgressWidget extends StatelessWidget {
  const MiniDownloadProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressService = DownloadProgressService();

    return StreamBuilder<GlobalDownloadProgress>(
      stream: progressService.progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasActiveDownloads) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 56, // Below app bar
          right: 16,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: progress.overallProgress,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress.overallProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (progress.averageSpeed > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${progress.averageSpeed.toStringAsFixed(1)} KB/s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
