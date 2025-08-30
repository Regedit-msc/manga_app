import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

class OfflineReader extends StatefulWidget {
  final OfflineReaderProps props;
  const OfflineReader({Key? key, required this.props}) : super(key: key);

  @override
  _OfflineReaderState createState() => _OfflineReaderState();
}

class _OfflineReaderState extends State<OfflineReader> {
  late Future<List<File>> _filesFuture;
  final PageController _pageController = PageController();
  final Map<int, TransformationController> _controllers = {};
  TapDownDetails? _tapDownDetails;
  @override
  void initState() {
    _filesFuture = _getFiles();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    super.initState();
  }

  Future<List<File>> _getFiles() async {
    final myDir = Directory(widget.props.chapterDir);
    if (!await myDir.exists()) return [];
    DebugLogger.logInfo('offline reader loading dir: ${myDir.path}',
        category: 'OfflineReader');
    final images = myDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) {
      // Filter only common image types and skip hidden/system files
      final name = f.uri.pathSegments.isNotEmpty
          ? f.uri.pathSegments.last
          : (f.path.split('/').isNotEmpty ? f.path.split('/').last : f.path);
      final lower = name.toLowerCase();
      final isHidden = lower.startsWith('.') || lower.startsWith('_');
      final isImage = lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.bmp');
      return !isHidden && isImage;
    }).toList();
    // Sort numerically by filename if possible (0.jpg, 1.jpg, ...)
    int key(File f) {
      String name;
      if (f.uri.pathSegments.isNotEmpty) {
        name = f.uri.pathSegments.last;
      } else {
        final parts = f.path.split('/');
        name = parts.isNotEmpty ? parts.last : f.path;
      }
      final numPart = RegExp(r'^(\d+)').firstMatch(name)?.group(1);
      return int.tryParse(numPart ?? '') ?? 1 << 30;
    }

    images.sort((a, b) {
      final ka = key(a);
      final kb = key(b);
      if (ka == kb) return a.path.compareTo(b.path);
      return ka.compareTo(kb);
    });
    DebugLogger.logInfo('offline reader files: ${images.length}',
        category: 'OfflineReader');
    return images;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    doCleanUp();
    super.dispose();
  }

  void doCleanUp() {
    Future.delayed(Duration(milliseconds: 100), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<File>>(
          future: _filesFuture,
          builder: (context, snapshot) {
            final files = snapshot.data ?? [];
            if (files.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No offline pages found for this chapter.',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final tController =
                        _controllers[index] ??= TransformationController();
                    return GestureDetector(
                      onTap: () => setState(() {}),
                      onDoubleTapDown: (details) => _tapDownDetails = details,
                      onDoubleTap: () {
                        final scale = 2.0;
                        final pos =
                            _tapDownDetails?.localPosition ?? Offset.zero;
                        final x = -pos.dx * (scale - 1);
                        final y = -pos.dy * (scale - 1);
                        final zoomed = Matrix4.identity()
                          ..translate(x, y)
                          ..scale(scale);
                        tController.value = tController.value.isIdentity()
                            ? zoomed
                            : Matrix4.identity();
                      },
                      child: InteractiveViewer(
                        transformationController: tController,
                        clipBehavior: Clip.none,
                        panEnabled: true,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final logicalWidth = constraints.maxWidth;
                            final pxWidth = (logicalWidth *
                                    MediaQuery.of(context).devicePixelRatio)
                                .clamp(320, 4096)
                                .toInt();
                            return Image(
                              image:
                                  ResizeImage(FileImage(file), width: pxWidth),
                              fit: BoxFit.fitWidth,
                              filterQuality: FilterQuality.medium,
                              // Simple placeholder while first frame decodes
                              frameBuilder: (ctx, child, frame, wasSync) {
                                if (frame == null) {
                                  return Container(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height,
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return child;
                              },
                              errorBuilder: (ctx, err, stack) => Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.broken_image_outlined, size: 48),
                                    SizedBox(height: 8),
                                    Text('Failed to load image'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // Realtime page indicator
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    left: false,
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) {
                        final total = files.length;
                        double page = 0;
                        if (_pageController.positions.isNotEmpty) {
                          page = _pageController.page ??
                              _pageController.initialPage.toDouble();
                        }
                        final current =
                            (page.clamp(0, (total - 1).toDouble()).floor() + 1)
                                .clamp(1, total);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black87.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            '$current / $total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class OfflineReaderProps {
  final String chapterDir;
  final DownloadedManga manga;
  OfflineReaderProps({required this.chapterDir, required this.manga});
}
