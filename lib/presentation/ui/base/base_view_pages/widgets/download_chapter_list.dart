import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart' as fd;
import 'package:timeago/timeago.dart' as timeago;
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_reader/offline_reader.dart';

class DownloadChapterListView extends StatefulWidget {
  final DownloadedManga downloadedManga;
  const DownloadChapterListView({Key? key, required this.downloadedManga})
      : super(key: key);

  @override
  _DownloadChapterListViewState createState() =>
      _DownloadChapterListViewState();
}

class _DownloadChapterListViewState extends State<DownloadChapterListView> {
  ValueNotifier<List<dynamic>> chapters = ValueNotifier([]);
  late String appDir;

  @override
  void initState() {
    doSetup();
    super.initState();
  }

  Future<void> doSetup() async {
    // final dir = await getApplicationDocumentsDirectory();
    // print(dir.path);
    final dir = await context.read<DownloadedCubit>().getAppDir();
    setState(() {
      appDir = dir;
    });
    List<fd.DownloadTask>? getTasks =
        await fd.FlutterDownloader.loadTasksWithRawQuery(
            query:
                'SELECT * FROM  task WHERE saved_dir LIKE "%${widget.downloadedManga.mangaName}%" AND status=3');
    if (getTasks != null && getTasks.isNotEmpty) {
      // Group by savedDir and pick the newest task per chapter folder
      final Map<String, fd.DownloadTask> newestPerDir = {};
      for (final t in getTasks) {
        final existing = newestPerDir[t.savedDir];
        if (existing == null ||
            _safeCompareEpoch(t.timeCreated, existing.timeCreated) > 0) {
          newestPerDir[t.savedDir] = t;
        }
      }

      // Sort chapters by newest first
      final chapterList = newestPerDir.values.toList()
        ..sort((a, b) => _safeCompareEpoch(b.timeCreated, a.timeCreated));

      if (chapterList.isNotEmpty) {
        DebugLogger.logInfo('downloaded chapters loaded: ${chapterList.length}',
            category: 'Downloader');
        chapters.value = chapterList;
      }
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.downloadedManga.mangaName),
      ),
      body: ValueListenableBuilder(
          valueListenable: chapters,
          builder: (context, List<dynamic> value, child) {
            if (value.isNotEmpty) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...List.generate(value.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.offlineReader,
                              arguments: OfflineReaderProps(
                                  chapterDir: value[index].savedDir,
                                  manga: widget.downloadedManga));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 0.1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: Sizes.dimen_100,
                                      height: Sizes.dimen_100,
                                      child: CachedNetworkImage(
                                        fadeInDuration:
                                            const Duration(microseconds: 100),
                                        imageUrl:
                                            widget.downloadedManga.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (ctx, string) {
                                          return Container(
                                              width: Sizes.dimen_100,
                                              height: Sizes.dimen_100,
                                              child: NoAnimationLoading());
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: Sizes.dimen_20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _chapterTitleFromSavedDir(
                                              value[index].savedDir),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: Sizes.dimen_10,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                  child: Padding(
                                padding: EdgeInsets.only(right: Sizes.dimen_2),
                                child: Text(
                                  timeago
                                      .format(_dateTimeFromEpoch(
                                          value[index].timeCreated))
                                      .replaceAll("ago", ""),
                                  style:
                                      const TextStyle(color: AppColor.violet),
                                ),
                              )),
                            ],
                          ),
                        ),
                      );
                    })
                  ],
                ),
              );
            }
            return Container();
          }),
    );
  }
}

String _chapterTitleFromSavedDir(String savedDir) {
  try {
    // Use last path segment and extract the last numeric group if present
    final tail =
        savedDir.split('/').isNotEmpty ? savedDir.split('/').last : savedDir;
    final matches = RegExp(r'(\d+)').allMatches(tail).toList();
    if (matches.isNotEmpty) {
      final numStr = matches.last.group(1);
      if (numStr != null && numStr.isNotEmpty) return 'Chapter $numStr';
    }
  } catch (_) {}
  return 'Chapter';
}

// Safely convert an epoch (seconds/millis/micros) to DateTime
DateTime _dateTimeFromEpoch(int epoch) {
  // Heuristic thresholds for units
  if (epoch > 100000000000000) {
    // > 1e14 -> microseconds
    return DateTime.fromMicrosecondsSinceEpoch(epoch);
  } else if (epoch > 100000000000) {
    // > 1e11 -> milliseconds
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  } else {
    // assume seconds
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  }
}

// Compare two epoch values regardless of unit by normalizing via DateTime
int _safeCompareEpoch(int a, int b) {
  final da = _dateTimeFromEpoch(a);
  final db = _dateTimeFromEpoch(b);
  return da.compareTo(db);
}
