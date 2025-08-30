import 'package:flutter/material.dart';
import '../../../data/services/download/download_progress_service.dart';

/// Global download progress bar widget that appears at the top of the app
class GlobalDownloadProgressBar extends StatelessWidget {
  const GlobalDownloadProgressBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalDownloadProgress>(
      stream: DownloadProgressService().progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasActiveDownloads) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;
        final double progressValue = progress.overallProgress;

        return Container(
          height: 3.0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

/// Download badge for bottom navigation
class DownloadBadge extends StatelessWidget {
  final Widget child;

  const DownloadBadge({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalDownloadProgress>(
      stream: DownloadProgressService().progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasActiveDownloads) {
          return child;
        }

        final activeCount = snapshot.data!.totalActiveChapters;

        return Badge(
          label: Text('$activeCount'),
          backgroundColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.onError,
          child: child,
        );
      },
    );
  }
}

/// Floating download progress indicator
class FloatingDownloadIndicator extends StatelessWidget {
  final VoidCallback? onTap;

  const FloatingDownloadIndicator({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalDownloadProgress>(
      stream: DownloadProgressService().progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasActiveDownloads) {
          return const SizedBox.shrink();
        }

        final progress = snapshot.data!;
        final activeCount = progress.totalActiveChapters;
        final overallProgress = progress.overallProgress;

        return Positioned(
          bottom: 16.0,
          right: 16.0,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(28.0),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28.0),
              child: Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.0),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress circle
                    SizedBox(
                      width: 48.0,
                      height: 48.0,
                      child: CircularProgressIndicator(
                        value: overallProgress,
                        strokeWidth: 2.0,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // Download icon with count
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download,
                          size: 20.0,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        if (activeCount > 1)
                          Text(
                            '$activeCount',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontSize: 10.0,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced chapter progress card
class EnhancedChapterProgressCard extends StatelessWidget {
  final ChapterProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const EnhancedChapterProgressCard({
    Key? key,
    required this.progress,
    this.onPause,
    this.onResume,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloading = progress.status == DownloadStatus.downloading;
    final isPaused = progress.status == DownloadStatus.paused;
    final isQueued = progress.status == DownloadStatus.queued;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with manga and chapter name
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.mangaName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        progress.chapterName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status icon
                _buildStatusIcon(context),
              ],
            ),

            const SizedBox(height: 12.0),

            // Progress bar
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(context),
              ),
            ),

            const SizedBox(height: 8.0),

            // Progress details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.progressText,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (progress.speedText.isNotEmpty)
                        Text(
                          progress.speedText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (progress.etaText.isNotEmpty)
                  Text(
                    progress.etaText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12.0),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloading && onPause != null)
                  TextButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause, size: 18.0),
                    label: const Text('Pause'),
                  ),
                if (isPaused && onResume != null)
                  TextButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow, size: 18.0),
                    label: const Text('Resume'),
                  ),
                if (isQueued)
                  Text(
                    'Queued',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18.0),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    final theme = Theme.of(context);

    switch (progress.status) {
      case DownloadStatus.downloading:
        return Icon(
          Icons.download,
          color: theme.colorScheme.primary,
          size: 20.0,
        );
      case DownloadStatus.paused:
        return Icon(
          Icons.pause,
          color: theme.colorScheme.outline,
          size: 20.0,
        );
      case DownloadStatus.queued:
        return Icon(
          Icons.schedule,
          color: theme.colorScheme.outline,
          size: 20.0,
        );
      case DownloadStatus.completed:
        return Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
          size: 20.0,
        );
      case DownloadStatus.failed:
        return Icon(
          Icons.error,
          color: theme.colorScheme.error,
          size: 20.0,
        );
      case DownloadStatus.cancelled:
        return Icon(
          Icons.cancel,
          color: theme.colorScheme.outline,
          size: 20.0,
        );
    }
  }

  Color _getProgressColor(BuildContext context) {
    final theme = Theme.of(context);

    switch (progress.status) {
      case DownloadStatus.downloading:
        return theme.colorScheme.primary;
      case DownloadStatus.paused:
        return theme.colorScheme.outline;
      case DownloadStatus.completed:
        return theme.colorScheme.primary;
      case DownloadStatus.failed:
        return theme.colorScheme.error;
      case DownloadStatus.cancelled:
        return theme.colorScheme.outline;
      case DownloadStatus.queued:
        return theme.colorScheme.outline;
    }
  }
}
