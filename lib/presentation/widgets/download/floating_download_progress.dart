import 'package:flutter/material.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';
import 'package:webcomic/presentation/pages/enhanced_download_management.dart';

/// Floating download progress indicator that shows current download status
class FloatingDownloadProgress extends StatelessWidget {
  const FloatingDownloadProgress({Key? key}) : super(key: key);

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
        final downloading = progress.downloadingChapters.length;
        final queued = progress.queuedChapters.length;

        return Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => _navigateToDownloadManager(context),
            child: Material(
              borderRadius: BorderRadius.circular(28),
              elevation: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress.overallProgress,
                        strokeWidth: 2.5,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Download info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          downloading > 0
                              ? 'Downloading $downloading'
                              : 'Queued $queued',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (progress.averageSpeed > 0)
                          Text(
                            '${progress.averageSpeed.toStringAsFixed(1)} KB/s',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 8),

                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.7),
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

  void _navigateToDownloadManager(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnhancedDownloadManagementPage(),
      ),
    );
  }
}

/// Compact download progress widget for use in app bars
class CompactDownloadProgress extends StatelessWidget {
  const CompactDownloadProgress({Key? key}) : super(key: key);

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

        return GestureDetector(
          onTap: () => _navigateToDownloadManager(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
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
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress.overallProgress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDownloadManager(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnhancedDownloadManagementPage(),
      ),
    );
  }
}

/// Download notification badge for navigation items
class DownloadNotificationBadge extends StatelessWidget {
  final Widget child;

  const DownloadNotificationBadge({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressService = DownloadProgressService();

    return StreamBuilder<GlobalDownloadProgress>(
      stream: progressService.progressStream,
      builder: (context, snapshot) {
        final hasDownloads =
            snapshot.hasData && snapshot.data!.hasActiveDownloads;

        return Stack(
          children: [
            child,
            if (hasDownloads)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    '${snapshot.data!.activeChapters.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
