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
  ValueNotifier<List<FileSystemEntity>> folders = ValueNotifier([]);
  @override
  void initState() {
    getDir();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    super.initState();
  }

  Future<void> getDir() async {
    final myDir = new Directory(widget.props.chapterDir);
    final images = myDir.listSync(recursive: true, followLinks: false);
    print(images.toString());
    folders.value = images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
          valueListenable: folders,
          builder: (context, value, child) {
            if (value != null) {
              final val = value as List<FileSystemEntity>;
              if (val.isNotEmpty) {
                final List<File> files = val.whereType<File>().toList();
                print(int.parse(files[0]
                    .path
                    .split(widget.props.chapterDir)[1]
                    .replaceAll("/", "")
                    .replaceAll(".jpg", "")));
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      ...List.generate(val.length, (index) {
                        print(widget.props.chapterDir + "/${index}.jpg");
                        return Image.file(
                            File(widget.props.chapterDir + "/${index}.jpg"));
                      })
                    ],
                  ),
                );
              }
            }
            return Container();
          }),
    );
  }
}

class OfflineReaderProps {
  final String chapterDir;
  final DownloadedManga manga;
  OfflineReaderProps({required this.chapterDir, required this.manga});
}
