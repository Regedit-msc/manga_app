import 'dart:async';

/// Enhanced download progress tracking service
class DownloadProgressService {
  static final DownloadProgressService _instance =
      DownloadProgressService._internal();
  factory DownloadProgressService() => _instance;
  DownloadProgressService._internal();

  final StreamController<GlobalDownloadProgress> _progressController =
      StreamController<GlobalDownloadProgress>.broadcast();

  Stream<GlobalDownloadProgress> get progressStream =>
      _progressController.stream;

  GlobalDownloadProgress _currentProgress = GlobalDownloadProgress();

  void updateProgress({
    required String mangaUrl,
    required String chapterUrl,
    required int totalImages,
    required int completedImages,
    required String mangaName,
    required String chapterName,
    DownloadStatus status = DownloadStatus.downloading,
    double? speedKbps,
    Duration? eta,
  }) {
    final chapterProgress = ChapterProgress(
      mangaUrl: mangaUrl,
      chapterUrl: chapterUrl,
      mangaName: mangaName,
      chapterName: chapterName,
      totalImages: totalImages,
      completedImages: completedImages,
      status: status,
      speedKbps: speedKbps,
      eta: eta,
      lastUpdate: DateTime.now(),
    );

    _currentProgress = _currentProgress.updateChapter(chapterProgress);
    _progressController.add(_currentProgress);
  }

  void removeChapter(String chapterUrl) {
    _currentProgress = _currentProgress.removeChapter(chapterUrl);
    _progressController.add(_currentProgress);
  }

  void clearAll() {
    _currentProgress = GlobalDownloadProgress();
    _progressController.add(_currentProgress);
  }

  GlobalDownloadProgress get currentProgress => _currentProgress;

  bool get hasActiveDownloads => _currentProgress.activeChapters.isNotEmpty;

  double get overallProgress => _currentProgress.overallProgress;

  void dispose() {
    _progressController.close();
  }
}

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class ChapterProgress {
  final String mangaUrl;
  final String chapterUrl;
  final String mangaName;
  final String chapterName;
  final int totalImages;
  final int completedImages;
  final DownloadStatus status;
  final double? speedKbps;
  final Duration? eta;
  final DateTime lastUpdate;

  const ChapterProgress({
    required this.mangaUrl,
    required this.chapterUrl,
    required this.mangaName,
    required this.chapterName,
    required this.totalImages,
    required this.completedImages,
    required this.status,
    this.speedKbps,
    this.eta,
    required this.lastUpdate,
  });

  double get progress => totalImages > 0 ? completedImages / totalImages : 0.0;

  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.paused;

  String get progressText => '$completedImages / $totalImages images';

  String get speedText =>
      speedKbps != null ? '${speedKbps!.toStringAsFixed(1)} KB/s' : '';

  String get etaText {
    if (eta == null) return '';
    final minutes = eta!.inMinutes;
    final seconds = eta!.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s remaining';
    }
    return '${seconds}s remaining';
  }

  ChapterProgress copyWith({
    String? mangaUrl,
    String? chapterUrl,
    String? mangaName,
    String? chapterName,
    int? totalImages,
    int? completedImages,
    DownloadStatus? status,
    double? speedKbps,
    Duration? eta,
    DateTime? lastUpdate,
  }) {
    return ChapterProgress(
      mangaUrl: mangaUrl ?? this.mangaUrl,
      chapterUrl: chapterUrl ?? this.chapterUrl,
      mangaName: mangaName ?? this.mangaName,
      chapterName: chapterName ?? this.chapterName,
      totalImages: totalImages ?? this.totalImages,
      completedImages: completedImages ?? this.completedImages,
      status: status ?? this.status,
      speedKbps: speedKbps ?? this.speedKbps,
      eta: eta ?? this.eta,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class GlobalDownloadProgress {
  final Map<String, ChapterProgress> _chapters;

  const GlobalDownloadProgress({Map<String, ChapterProgress>? chapters})
      : _chapters = chapters ?? const {};

  List<ChapterProgress> get allChapters => _chapters.values.toList();

  List<ChapterProgress> get activeChapters =>
      _chapters.values.where((c) => c.isActive).toList();

  bool get hasActiveDownloads => activeChapters.isNotEmpty;

  List<ChapterProgress> get downloadingChapters => _chapters.values
      .where((c) => c.status == DownloadStatus.downloading)
      .toList();

  List<ChapterProgress> get queuedChapters =>
      _chapters.values.where((c) => c.status == DownloadStatus.queued).toList();

  int get totalActiveChapters => activeChapters.length;

  int get totalCompletedChapters => _chapters.values
      .where((c) => c.status == DownloadStatus.completed)
      .length;

  double get overallProgress {
    if (_chapters.isEmpty) return 0.0;
    final totalImages =
        _chapters.values.fold(0, (sum, c) => sum + c.totalImages);
    final completedImages =
        _chapters.values.fold(0, (sum, c) => sum + c.completedImages);
    return totalImages > 0 ? completedImages / totalImages : 0.0;
  }

  double get averageSpeed {
    final downloadingWithSpeed =
        downloadingChapters.where((c) => c.speedKbps != null).toList();
    if (downloadingWithSpeed.isEmpty) return 0.0;
    return downloadingWithSpeed.fold(0.0, (sum, c) => sum + c.speedKbps!) /
        downloadingWithSpeed.length;
  }

  String get statusSummary {
    if (activeChapters.isEmpty) return 'No active downloads';
    final downloading = downloadingChapters.length;
    final queued = queuedChapters.length;

    if (downloading > 0 && queued > 0) {
      return 'Downloading $downloading, $queued queued';
    } else if (downloading > 0) {
      return 'Downloading $downloading chapter${downloading > 1 ? 's' : ''}';
    } else {
      return '$queued chapter${queued > 1 ? 's' : ''} queued';
    }
  }

  GlobalDownloadProgress updateChapter(ChapterProgress chapter) {
    final newChapters = Map<String, ChapterProgress>.from(_chapters);
    newChapters[chapter.chapterUrl] = chapter;
    return GlobalDownloadProgress(chapters: newChapters);
  }

  GlobalDownloadProgress removeChapter(String chapterUrl) {
    final newChapters = Map<String, ChapterProgress>.from(_chapters);
    newChapters.remove(chapterUrl);
    return GlobalDownloadProgress(chapters: newChapters);
  }
}
