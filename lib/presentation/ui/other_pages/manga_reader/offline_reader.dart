import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';

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
    final images = myDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .toList();
    images.sort((a, b) => a.path.compareTo(b.path));
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
            if (files.isEmpty) return const SizedBox.shrink();
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
