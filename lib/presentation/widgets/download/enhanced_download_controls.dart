import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloading_cubit.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

/// Enhanced pause/resume button with better UX
class EnhancedPauseResumeButton extends StatefulWidget {
  final DownloadingState downloading;
  final String chapterUrl;
  final List<int> progress;

  const EnhancedPauseResumeButton({
    Key? key,
    required this.downloading,
    required this.chapterUrl,
    required this.progress,
  }) : super(key: key);

  @override
  State<EnhancedPauseResumeButton> createState() =>
      _EnhancedPauseResumeButtonState();
}

class _EnhancedPauseResumeButtonState extends State<EnhancedPauseResumeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isRunning {
    final downloads = widget.downloading.downloads
        .where((e) => e["chapterUrl"] == widget.chapterUrl)
        .toList();
    return downloads.any((e) => e["status"] == DownloadTaskStatus.running);
  }

  bool get _isPaused {
    final downloads = widget.downloading.downloads
        .where((e) => e["chapterUrl"] == widget.chapterUrl)
        .toList();
    return downloads.any((e) => e["status"] == DownloadTaskStatus.paused);
  }

  bool get _isCompleted {
    return (widget.progress[1] / (widget.progress[0] * 100)) >= 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
        setState(() => _isProcessing = true);
      },
      onTapUp: (_) async {
        _animationController.reverse();
        await _handleTap();
        setState(() => _isProcessing = false);
      },
      onTapCancel: () {
        _animationController.reverse();
        setState(() => _isProcessing = false);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getButtonColor().withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getButtonColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getButtonColor()),
                      ),
                    )
                  : Icon(
                      _getButtonIcon(),
                      color: _getButtonColor(),
                      size: 16,
                    ),
            ),
          );
        },
      ),
    );
  }

  Color _getButtonColor() {
    if (_isRunning) return Colors.orange;
    if (_isPaused) return Colors.blue;
    return Colors.grey[600]!;
  }

  IconData _getButtonIcon() {
    if (_isRunning) return Icons.pause;
    if (_isPaused) return Icons.play_arrow;
    return Icons.refresh;
  }

  Future<void> _handleTap() async {
    try {
      if (_isRunning) {
        await context.read<DownloadingCubit>().pauseChapterDownload(
              chapterUrl: widget.chapterUrl,
            );
      } else {
        await context.read<DownloadingCubit>().resumeChapterDownload(
              chapterUrl: widget.chapterUrl,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to ${_isRunning ? 'pause' : 'resume'} download'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Enhanced progress indicator with better visual feedback
class EnhancedProgressIndicator extends StatelessWidget {
  final DownloadingState downloading;
  final String chapterUrl;
  final List<int> progress;

  const EnhancedProgressIndicator({
    Key? key,
    required this.downloading,
    required this.chapterUrl,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressValue = _getProgressValue();
    final status = _getDownloadStatus();

    return Container(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getBackgroundColor(status).withOpacity(0.1),
            ),
          ),

          // Progress circle
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 3,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getProgressColor(status)),
            ),
          ),

          // Status icon
          Icon(
            _getStatusIcon(status),
            size: 16,
            color: _getProgressColor(status),
          ),

          // Progress percentage text (for downloading state)
          if (status == DownloadStatus.downloading && progressValue > 0)
            Text(
              '${(progressValue * 100).toInt()}%',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: _getProgressColor(status),
              ),
            ),
        ],
      ),
    );
  }

  double _getProgressValue() {
    if (progress.isEmpty || progress[0] == 0) return 0.0;
    final value = progress[1] / (progress[0] * 100);
    if (value.isNaN || value.isInfinite || value < 0) return 0.0;
    return value.clamp(0.0, 1.0);
  }

  DownloadStatus _getDownloadStatus() {
    final downloads = downloading.downloads
        .where((e) => e["chapterUrl"] == chapterUrl)
        .toList();

    if (downloads.isEmpty) return DownloadStatus.queued;

    if (downloads.any((e) => e["status"] == DownloadTaskStatus.running)) {
      return DownloadStatus.downloading;
    }
    if (downloads.any((e) => e["status"] == DownloadTaskStatus.paused)) {
      return DownloadStatus.paused;
    }
    if (downloads.every((e) => e["status"] == DownloadTaskStatus.complete)) {
      return DownloadStatus.completed;
    }
    if (downloads.any((e) => e["status"] == DownloadTaskStatus.failed)) {
      return DownloadStatus.failed;
    }
    if (downloads.every((e) => e["status"] == DownloadTaskStatus.enqueued)) {
      return DownloadStatus.queued;
    }

    return DownloadStatus.queued;
  }

  Color _getProgressColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.queued:
        return Colors.grey[600]!;
      case DownloadStatus.cancelled:
        return Colors.grey[400]!;
    }
  }

  Color _getBackgroundColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.queued:
        return Colors.grey;
      case DownloadStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.paused:
        return Icons.pause;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.queued:
        return Icons.schedule;
      case DownloadStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// Status for download progress
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Enhanced chapter download card with better progress visualization
class EnhancedChapterDownloadCard extends StatelessWidget {
  final String chapterTitle;
  final String chapterUrl;
  final String mangaImageUrl;
  final DownloadingState downloading;
  final List<int> progress;
  final VoidCallback? onCancel;

  const EnhancedChapterDownloadCard({
    Key? key,
    required this.chapterTitle,
    required this.chapterUrl,
    required this.mangaImageUrl,
    required this.downloading,
    required this.progress,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.isNotEmpty && progress[0] > 0
        ? (progress[1] / (progress[0] * 100)).clamp(0.0, 1.0)
        : 0.0;

    final speed = _getDownloadSpeed();
    final eta = _getETA(progressValue, speed);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Chapter image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(mangaImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatChapterTitle(chapterTitle),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.isNotEmpty ? progress[1] ~/ 100 : 0} / ${progress.isNotEmpty ? progress[0] : 0} images',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicator and controls
                Row(
                  children: [
                    EnhancedProgressIndicator(
                      downloading: downloading,
                      chapterUrl: chapterUrl,
                      progress: progress,
                    ),
                    const SizedBox(width: 8),
                    EnhancedPauseResumeButton(
                      downloading: downloading,
                      chapterUrl: chapterUrl,
                      progress: progress,
                    ),
                    if (onCancel != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressValue >= 1.0 ? Colors.green : AppColor.violet,
              ),
            ),

            const SizedBox(height: 8),

            // Progress details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progressValue * 100).toInt()}% complete',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (speed > 0 && progressValue < 1.0)
                  Text(
                    '$speed KB/s • $eta',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatChapterTitle(String title) {
    try {
      final parts = title.replaceAll("-", " ").split(" ");
      final chapterIndex =
          parts.indexWhere((e) => e.toLowerCase() == "chapter");
      if (chapterIndex != -1 && chapterIndex + 1 < parts.length) {
        final chapterNumber = parts[chapterIndex + 1];
        final chapterTitle =
            chapterIndex + 2 < parts.length ? parts[chapterIndex + 2] : "";
        return "Chapter $chapterNumber${chapterTitle.isNotEmpty ? ' - $chapterTitle' : ''}";
      }
      return title.replaceAll("-", " ");
    } catch (e) {
      return title.replaceAll("-", " ");
    }
  }

  double _getDownloadSpeed() {
    // This would ideally come from the download service
    // For now, return a mock value
    final downloads = downloading.downloads
        .where((e) =>
            e["chapterUrl"] == chapterUrl &&
            e["status"] == DownloadTaskStatus.running)
        .toList();
    return downloads.isNotEmpty ? 150.0 : 0.0; // Mock speed in KB/s
  }

  String _getETA(double progressValue, double speed) {
    if (progressValue >= 1.0 || speed <= 0) return "";

    final remainingProgress = 1.0 - progressValue;
    final totalImages = progress.isNotEmpty ? progress[0] : 0;
    final avgImageSize = 100; // KB (mock value)
    final remainingSize = remainingProgress * totalImages * avgImageSize;
    final etaSeconds = (remainingSize / speed).round();

    if (etaSeconds < 60) {
      return "${etaSeconds}s left";
    } else {
      final minutes = etaSeconds ~/ 60;
      final seconds = etaSeconds % 60;
      return "${minutes}m ${seconds}s left";
    }
  }
}
