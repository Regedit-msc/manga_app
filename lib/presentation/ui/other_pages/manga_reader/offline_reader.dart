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
        .toList();
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
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  ...List.generate(files.length, (index) {
                    final path = files[index].path;
                    return Image.file(File(path));
                  })
                ],
              ),
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
