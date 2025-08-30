import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

class MangaReader extends StatefulWidget {
  final ChapterList chapterList;

  const MangaReader({Key? key, required this.chapterList}) : super(key: key);

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<String> chapterName = ValueNotifier('');
  TapDownDetails? tapDownDetails;
  final Map<int, TransformationController> _controllers = {};
  late final PageController _pageController;
  bool showAppBar = false;
  // Track the current chapter URL explicitly to make URL-based matching reliable
  late String _currentChapterUrl;

  // Parse chapter number from strings like "Chapter 12", "Ch. 12.5", "12", "12_extra"
  double? _parseChapterNumber(String raw) {
    try {
      final match = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(raw);
      if (match != null) return double.tryParse(match.group(0)!);
      return null;
    } catch (_) {
      return null;
    }
  }

  // Find index of current chapter prioritizing URL match, then title, then numeric compare
  int _findCurrentIndex(GetMangaReaderData data) {
    final list = data.chapterList ?? [];
    if (list.isEmpty) return -1;

    // 1) Try by current URL tracked in state
    if (_currentChapterUrl.isNotEmpty) {
      final urlIdx = list.indexWhere((e) => e.chapterUrl == _currentChapterUrl);
      if (urlIdx != -1) return urlIdx;
    }

    // 2) Try perfect title match against server-provided current title
    final exactIdx =
        list.indexWhere((e) => e.chapterTitle.trim() == data.chapter.trim());
    if (exactIdx != -1) return exactIdx;

    // 3) Fallback: numeric compare between current chapter title and list items
    final currentNum = _parseChapterNumber(data.chapter);
    if (currentNum != null) {
      for (int i = 0; i < list.length; i++) {
        final n = _parseChapterNumber(list[i].chapterTitle);
        if (n != null && (n - currentNum).abs() < 1e-9) return i;
      }
    }
    return -1;
  }

  // Determine if the list is newest-first (descending numbers) or oldest-first (ascending)
  bool _isNewestFirst(GetMangaReaderData data) {
    final list = data.chapterList ?? [];
    if (list.length < 2) return true; // default to newest-first

    double? firstNum;
    for (int i = 0; i < list.length; i++) {
      final n = _parseChapterNumber(list[i].chapterTitle);
      if (n != null) {
        if (firstNum == null) {
          firstNum = n;
        } else {
          // Compare the first two numeric chapters we can find in order
          return firstNum >= n; // true -> descending (newest-first)
        }
      }
    }

    // Fallback: try dates if available (some sources supply date strings)
    DateTime? _parseDate(String? s) {
      if (s == null) return null;
      try {
        return DateTime.tryParse(s);
      } catch (_) {
        return null;
      }
    }

    final firstDate = _parseDate(list.first.dateUploaded);
    final lastDate = _parseDate(list.last.dateUploaded);
    if (firstDate != null && lastDate != null) {
      return firstDate.isAfter(lastDate); // true -> first is newer
    }

    return true; // safe default
  }

  ReaderChapterItem? _getNextChapter(GetMangaReaderData data) {
    // Next = newer chapter regardless of server list ordering
    final list = data.chapterList ?? [];
    if (list.isEmpty) return null;
    final idx = _findCurrentIndex(data);
    final newestFirst = _isNewestFirst(data);
    if (idx != -1) {
      final nextIdx = newestFirst ? idx - 1 : idx + 1;
      if (nextIdx >= 0 && nextIdx < list.length) return list[nextIdx];
      return null; // no newer chapter
    }

    // Fallback when current chapter isn't in the list: use numeric compare
    final currentNum = _parseChapterNumber(data.chapter) ??
        _parseChapterNumber(_currentChapterUrl);
    if (currentNum == null) return null;
    double? candidateNum;
    int? candidateIdx;
    for (int i = 0; i < list.length; i++) {
      final n = _parseChapterNumber(list[i].chapterTitle);
      if (n == null) continue;
      // newer = higher chapter number
      if (n > currentNum) {
        if (candidateNum == null || n < candidateNum) {
          candidateNum = n;
          candidateIdx = i;
        }
      }
    }
    if (candidateIdx != null) {
      DebugLogger.logInfo(
        'Fallback NEXT chose index=$candidateIdx num=$candidateNum for currentNum=$currentNum',
        category: 'READER_NAV',
      );
      return list[candidateIdx];
    }
    DebugLogger.logInfo(
      'Fallback NEXT found no newer chapter for currentNum=$currentNum',
      category: 'READER_NAV',
    );
    return null;
  }

  ReaderChapterItem? _getPrevChapter(GetMangaReaderData data) {
    // Prev = older chapter regardless of server list ordering
    final list = data.chapterList ?? [];
    if (list.isEmpty) return null;
    final idx = _findCurrentIndex(data);
    final newestFirst = _isNewestFirst(data);
    if (idx != -1) {
      final prevIdx = newestFirst ? idx + 1 : idx - 1;
      if (prevIdx >= 0 && prevIdx < list.length) return list[prevIdx];
      return null; // no older chapter
    }

    // Fallback when current chapter isn't in the list: use numeric compare
    final currentNum = _parseChapterNumber(data.chapter) ??
        _parseChapterNumber(_currentChapterUrl);
    if (currentNum == null) return null;
    double? candidateNum;
    int? candidateIdx;
    for (int i = 0; i < list.length; i++) {
      final n = _parseChapterNumber(list[i].chapterTitle);
      if (n == null) continue;
      // older = lower chapter number
      if (n < currentNum) {
        if (candidateNum == null || n > candidateNum) {
          candidateNum = n;
          candidateIdx = i;
        }
      }
    }
    if (candidateIdx != null) {
      DebugLogger.logInfo(
        'Fallback PREV chose index=$candidateIdx num=$candidateNum for currentNum=$currentNum',
        category: 'READER_NAV',
      );
      return list[candidateIdx];
    }
    DebugLogger.logInfo(
      'Fallback PREV found no older chapter for currentNum=$currentNum',
      category: 'READER_NAV',
    );
    return null;
  }

  // Helper method to safely extract chapter number from string
  int? extractChapterNumber(String chapterString) {
    try {
      List<String> parts = chapterString.replaceAll("-", " ").split(" ");
      int chapterIndex =
          parts.indexWhere((element) => element.toLowerCase() == "chapter");

      if (chapterIndex == -1 || chapterIndex + 1 >= parts.length) {
        // If "chapter" keyword not found or no number after it, try to extract first number
        RegExp numberRegex = RegExp(r'\d+');
        Match? match = numberRegex.firstMatch(chapterString);
        if (match != null) {
          return int.parse(match.group(0)!);
        }
        return null;
      }

      String chapterNumberStr = parts[chapterIndex + 1];
      // Remove any non-numeric characters except digits
      chapterNumberStr = chapterNumberStr.replaceAll(RegExp(r'[^\d]'), '');

      if (chapterNumberStr.isEmpty) return null;

      return int.parse(chapterNumberStr);
    } catch (e) {
      print("Error extracting chapter number from: $chapterString - $e");
      return null;
    }
  }

  // Helper method to safely format chapter title for display
  String formatChapterTitle(String chapterString) {
    try {
      List<String> parts = chapterString.replaceAll("-", " ").split(" ");
      int chapterIndex =
          parts.indexWhere((element) => element.toLowerCase() == "chapter");

      if (chapterIndex == -1 || chapterIndex + 1 >= parts.length) {
        // If "chapter" keyword not found, return formatted string
        return chapterString.replaceAll("-", " ");
      }

      String chapterNumber = parts[chapterIndex + 1];
      String chapterTitle =
          chapterIndex + 2 < parts.length ? parts[chapterIndex + 2] : "";

      // Capitalize first letter of chapter number
      if (chapterNumber.isNotEmpty) {
        chapterNumber =
            chapterNumber[0].toUpperCase() + chapterNumber.substring(1);
      }

      return "$chapterNumber ${chapterTitle}".trim();
    } catch (e) {
      // Return safe fallback
      return chapterString.replaceAll("-", " ");
    }
  }

  Future preLoadImages(List<String> listOfUrls) async {
    // Preload only a few images eagerly to avoid OOM on large chapters
    final eager = listOfUrls.take(3).toList();
    await Future.wait(eager.map((image) => cacheImage(context, image)));
    if (mounted) isLoading.value = false;

    // Then slowly preload the rest in background (non-blocking)
    Future(() async {
      final rest = listOfUrls.skip(3);
      for (final image in rest) {
        try {
          await cacheImage(context, image);
          // small delay so we don't saturate the network
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (_) {
          // ignore individual preload failures
        }
        if (!mounted) break;
      }
    });
  }

  Future cacheImage(BuildContext context, String image) =>
      precacheImage(CachedNetworkImageProvider(image), context);

  FetchMoreOptions toNewPageOptions(String newChapterUrl) {
    return FetchMoreOptions(
      variables: {
        'chapterUrl': newChapterUrl,
        'source': widget.chapterList.mangaSource ?? '',
      },
      updateQuery: (previousResultData, fetchMoreResultData) {
        return fetchMoreResultData;
      },
    );
  }

  @override
  void initState() {
    chapterName.value = widget.chapterList.chapterTitle;
    _pageController = PageController();
    _scrollController.addListener(scrollListener);
    _currentChapterUrl = widget.chapterList.chapterUrl;
    super.initState();
  }

  @override
  void dispose() {
    chapterName.dispose();
    isLoading.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Brightness getBrightNess() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = context.read<ThemeCubit>().state.themeMode;
    if (theme == ThemeMode.dark) return Brightness.light;
    if (theme == ThemeMode.light) return Brightness.dark;
    return brightness == Brightness.light ? Brightness.dark : Brightness.light;
  }

  Color getOverlayColor() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = context.read<ThemeCubit>().state.themeMode;
    if (theme == ThemeMode.dark) return AppColor.vulcan;
    if (theme == ThemeMode.light) return Colors.white;
    return brightness == Brightness.light ? Colors.white : AppColor.vulcan;
  }

  void scrollListener() {
    if (!mounted) return;
    final atEnd = _scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent;
    if (atEnd && !showAppBar) {
      setState(() => showAppBar = true);
    } else if (!atEnd && showAppBar) {
      setState(() => showAppBar = false);
    }
  }

  Future<void> doTheFunStuff({
    String theNextChapterUrl = '',
    String theNextChapterTitle = "",
    dynamic fetchMore,
  }) async {
    DebugLogger.logInfo(
      'Navigating to chapter: "$theNextChapterTitle" ($theNextChapterUrl)',
      category: 'READER_NAV',
    );
    final DatabaseHelper dbInstance = getItInstance<DatabaseHelper>();
    ChapterRead newChapter = ChapterRead(
        mangaUrl: widget.chapterList.mangaUrl, chapterUrl: theNextChapterUrl);
    RecentlyRead recentlyRead = RecentlyRead(
        title: widget.chapterList.mangaTitle,
        mangaUrl: widget.chapterList.mangaUrl,
        imageUrl: widget.chapterList.mangaImage,
        chapterUrl: theNextChapterUrl,
        chapterTitle: theNextChapterTitle,
        mostRecentReadDate: DateTime.now().toString(),
        mangaSource: widget.chapterList.mangaSource);
    chapterName.value = recentlyRead.chapterTitle;
    _currentChapterUrl = theNextChapterUrl; // keep URL indexer in sync
    List<RecentlyRead> recents = context.read<RecentsCubit>().state.recents;
    List<ChapterRead> chaptersRead =
        context.read<ChaptersReadCubit>().state.chaptersRead;
    List<RecentlyRead> withoutCurrentRead = recents
        .where((element) => element.mangaUrl != recentlyRead.mangaUrl)
        .toList();
    List<ChapterRead> withoutCurrentChapter = chaptersRead
        .where((element) => element.chapterUrl != newChapter.chapterUrl)
        .toList();

    context
        .read<RecentsCubit>()
        .setResults([...withoutCurrentRead, recentlyRead]);
    context
        .read<ChaptersReadCubit>()
        .setResults([...withoutCurrentChapter, newChapter]);
    await fetchMore!(toNewPageOptions(theNextChapterUrl));
    await dbInstance.updateOrInsertChapterRead(newChapter);
    await dbInstance.updateOrInsertRecentlyRead(recentlyRead);
  }

  void _logChapterTap(String action, GetMangaReaderData data,
      {ReaderChapterItem? target, String? reason}) {
    final list = data.chapterList ?? [];
    final idx = _findCurrentIndex(data);
    final newestFirst = _isNewestFirst(data);
    final currentTitle = data.chapter;
    final currentUrl = _currentChapterUrl;
    DebugLogger.logInfo(
      '$action — currentIdx=$idx, listLen=${list.length}, newestFirst=$newestFirst\n'
      'currentTitle="$currentTitle"\n'
      'currentUrl=$currentUrl\n'
      'first="${list.isNotEmpty ? list.first.chapterTitle : ''}" last="${list.isNotEmpty ? list.last.chapterTitle : ''}"\n'
      '${target != null ? 'targetTitle="${target.chapterTitle}" targetUrl=${target.chapterUrl}' : 'no target'}'
      '${reason != null ? '\nreason=$reason' : ''}',
      category: 'READER_NAV',
    );
  }

  Widget checkLast(List<ReaderChapterItem>? chapterList, String chapter,
      GetMangaReader mangaReader) {
    final next = _getNextChapter(mangaReader.data);
    if (next != null) {
      final nextLabel = formatChapterTitle(next.chapterTitle);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          color: context.isLightMode() ? AppColor.vulcan : Colors.white,
          child: Row(
            children: [
              Container(
                width: Sizes.dimen_140.w,
                height: Sizes.dimen_50.h,
                child: CachedNetworkImage(
                  imageUrl: mangaReader.data.images.length > 1
                      ? mangaReader.data.images[1]
                      : mangaReader.data.images.first,
                  fit: BoxFit.cover,
                  placeholder: (ctx, string) => const Loading(),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: Sizes.dimen_40.w),
                child: Text(
                  "Next: $nextLabel",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          context.isLightMode() ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const Text("Last Chapter");
  }

  @override
  Widget build(BuildContext context) {
    double barHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness:
              showAppBar ? getBrightNess() : Brightness.dark,
          statusBarColor: showAppBar ? getOverlayColor() : Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          toolbarHeight: 0.0,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
              statusBarIconBrightness:
                  showAppBar ? getBrightNess() : Brightness.dark,
              statusBarColor:
                  showAppBar ? getOverlayColor() : Colors.transparent),
        ),
        body: Query(
            options: QueryOptions(
              document: parseString(MANGA_READER),
              variables: {
                'chapterUrl': widget.chapterList.chapterUrl,
                'source': widget.chapterList.mangaSource ?? '',
              },
              pollInterval: null,
            ),
            builder: (QueryResult result, {refetch, fetchMore}) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }

              if (result.isLoading) {
                return const Loading();
              }
              dynamic mangaToRead = result.data?["getMangaReader"];

              if (mangaToRead != null) {
                GetMangaReader mangaReader =
                    GetMangaReader.fromMap(mangaToRead);
                // Log load context: detected order, index, boundaries
                try {
                  final idx = _findCurrentIndex(mangaReader.data);
                  final newestFirst = _isNewestFirst(mangaReader.data);
                  final list = mangaReader.data.chapterList ?? [];
                  DebugLogger.logInfo(
                    'Loaded reader data — idx=$idx, listLen=${list.length}, newestFirst=$newestFirst\n'
                    'currentTitle="${mangaReader.data.chapter}"\n'
                    'currentUrl=$_currentChapterUrl\n'
                    'first="${list.isNotEmpty ? list.first.chapterTitle : ''}" last="${list.isNotEmpty ? list.last.chapterTitle : ''}"',
                    category: 'READER_NAV',
                  );
                } catch (_) {}
                if (context
                    .read<SettingsCubit>()
                    .state
                    .settings
                    .preloadImages) {
                  preLoadImages(mangaReader.data.images);
                } else {
                  isLoading.value = false;
                }
                return ValueListenableBuilder(
                    valueListenable: isLoading,
                    builder: (context, bool val, child) {
                      return !val
                          ? LayoutBuilder(builder: (context, contraint) {
                              return Stack(
                                children: [
                                  PageView.builder(
                                    controller: _pageController,
                                    scrollDirection: Axis.vertical,
                                    itemCount:
                                        mangaReader.data.images.length + 1,
                                    itemBuilder: (context, idx) {
                                      if (idx <
                                          mangaReader.data.images.length) {
                                        final index = idx;
                                        final tController =
                                            _controllers[index] ??=
                                                TransformationController();
                                        return GestureDetector(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                showAppBar = !showAppBar;
                                              });
                                            }
                                          },
                                          onDoubleTap: () {
                                            final double scale = 2;
                                            final position =
                                                tapDownDetails?.localPosition ??
                                                    Offset.zero;
                                            final x =
                                                -position.dx * (scale - 1);
                                            final y =
                                                -position.dy * (scale - 1);

                                            final zoomed = Matrix4.identity()
                                              ..translate(x, y)
                                              ..scale(scale);
                                            final value =
                                                tController.value.isIdentity()
                                                    ? zoomed
                                                    : Matrix4.identity();
                                            tController.value = value;
                                          },
                                          onDoubleTapDown: (details) =>
                                              tapDownDetails = details,
                                          child: InteractiveViewer(
                                            transformationController:
                                                tController,
                                            clipBehavior: Clip.none,
                                            panEnabled: true,
                                            child: CachedNetworkImage(
                                              fadeInDuration: const Duration(
                                                  milliseconds: 200),
                                              imageUrl: mangaReader
                                                  .data.images[index],
                                              fit: BoxFit.fitWidth,
                                              placeholder: (ctx, string) {
                                                return Container(
                                                  height:
                                                      ScreenUtil.screenHeight,
                                                  width: ScreenUtil.screenWidth,
                                                  color: context.isLightMode()
                                                      ? Colors.white
                                                      : AppColor.vulcan,
                                                  child: const Center(
                                                      child:
                                                          NoAnimationLoading()),
                                                );
                                              },
                                              errorWidget: (ctx, url, error) =>
                                                  Container(
                                                height: ScreenUtil.screenHeight,
                                                width: ScreenUtil.screenWidth,
                                                color: context.isLightMode()
                                                    ? Colors.white
                                                    : AppColor.vulcan,
                                                child: const Center(
                                                    child: Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 48,
                                                )),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      // trailing next-chapter card
                                      return contraint.biggest.height <
                                              ScreenUtil.screenHeight
                                          ? const SizedBox.shrink()
                                          : GestureDetector(
                                              onTap: () async {
                                                final next = _getNextChapter(
                                                    mangaReader.data);
                                                _logChapterTap(
                                                  'Next Tap (page end)',
                                                  mangaReader.data,
                                                  target: next,
                                                  reason: next == null
                                                      ? 'No newer chapter found'
                                                      : null,
                                                );
                                                if (next == null) {
                                                  getItInstance<
                                                          ToastServiceImpl>()
                                                      .showToast(
                                                          "No newer chapter available.",
                                                          Toast.LENGTH_SHORT);
                                                  return;
                                                }
                                                await doTheFunStuff(
                                                  theNextChapterTitle:
                                                      next.chapterTitle,
                                                  theNextChapterUrl:
                                                      next.chapterUrl,
                                                  fetchMore: fetchMore,
                                                );
                                              },
                                              child: ValueListenableBuilder(
                                                valueListenable: isLoading,
                                                builder:
                                                    (context, bool loading, _) {
                                                  return !loading
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: checkLast(
                                                              mangaReader.data
                                                                  .chapterList,
                                                              mangaReader
                                                                  .data.chapter,
                                                              mangaReader))
                                                      : const SizedBox.shrink();
                                                },
                                              ),
                                            );
                                    },
                                  ),
                                  if (showAppBar)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: SafeArea(
                                        top: false,
                                        child: Container(
                                          margin: const EdgeInsets.all(12),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: (context.isLightMode()
                                                    ? Colors.white
                                                    : AppColor.vulcan)
                                                .withOpacity(0.95),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.12),
                                                blurRadius: 16,
                                                offset: const Offset(0, -2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: context.isLightMode()
                                                  ? Colors.black12
                                                  : Colors.white10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: ScaleAnim(
                                                  onTap: () async {
                                                    final prev =
                                                        _getPrevChapter(
                                                            mangaReader.data);
                                                    _logChapterTap(
                                                      'Prev Tap (overlay onTap)',
                                                      mangaReader.data,
                                                      target: prev,
                                                      reason: prev == null
                                                          ? "You're at the first/oldest chapter"
                                                          : null,
                                                    );
                                                    if (prev == null) {
                                                      getItInstance<
                                                              ToastServiceImpl>()
                                                          .showToast(
                                                              "You're at the first chapter.",
                                                              Toast
                                                                  .LENGTH_SHORT);
                                                      return;
                                                    }
                                                    await doTheFunStuff(
                                                      theNextChapterUrl:
                                                          prev.chapterUrl,
                                                      theNextChapterTitle:
                                                          prev.chapterTitle,
                                                      fetchMore: fetchMore,
                                                    );
                                                  },
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final prev =
                                                          _getPrevChapter(
                                                              mangaReader.data);
                                                      _logChapterTap(
                                                        'Prev Tap (overlay onPressed)',
                                                        mangaReader.data,
                                                        target: prev,
                                                        reason: prev == null
                                                            ? "You're at the first/oldest chapter"
                                                            : null,
                                                      );
                                                      if (prev == null) {
                                                        getItInstance<
                                                                ToastServiceImpl>()
                                                            .showToast(
                                                                "You're at the first chapter.",
                                                                Toast
                                                                    .LENGTH_SHORT);
                                                        return;
                                                      }
                                                      await doTheFunStuff(
                                                        theNextChapterUrl:
                                                            prev.chapterUrl,
                                                        theNextChapterTitle:
                                                            prev.chapterTitle,
                                                        fetchMore: fetchMore,
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColor.royalBlue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12,
                                                              horizontal: 8),
                                                      shape:
                                                          const StadiumBorder(),
                                                      elevation: 0,
                                                    ),
                                                    icon: const Icon(
                                                        Icons.arrow_left),
                                                    label: const Text("Prev"),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ScaleAnim(
                                                  onTap: () async {
                                                    final next =
                                                        _getNextChapter(
                                                            mangaReader.data);
                                                    _logChapterTap(
                                                      'Next Tap (overlay onTap)',
                                                      mangaReader.data,
                                                      target: next,
                                                      reason: next == null
                                                          ? 'No newer chapter available'
                                                          : null,
                                                    );
                                                    if (next == null) {
                                                      getItInstance<
                                                              ToastServiceImpl>()
                                                          .showToast(
                                                              "No newer chapter available.",
                                                              Toast
                                                                  .LENGTH_SHORT);
                                                      return;
                                                    }
                                                    await doTheFunStuff(
                                                      theNextChapterTitle:
                                                          next.chapterTitle,
                                                      theNextChapterUrl:
                                                          next.chapterUrl,
                                                      fetchMore: fetchMore,
                                                    );
                                                  },
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final next =
                                                          _getNextChapter(
                                                              mangaReader.data);
                                                      _logChapterTap(
                                                        'Next Tap (overlay onPressed)',
                                                        mangaReader.data,
                                                        target: next,
                                                        reason: next == null
                                                            ? 'No newer chapter available'
                                                            : null,
                                                      );
                                                      if (next == null) {
                                                        getItInstance<
                                                                ToastServiceImpl>()
                                                            .showToast(
                                                                "No newer chapter available.",
                                                                Toast
                                                                    .LENGTH_SHORT);
                                                        return;
                                                      }
                                                      await doTheFunStuff(
                                                        theNextChapterTitle:
                                                            next.chapterTitle,
                                                        theNextChapterUrl:
                                                            next.chapterUrl,
                                                        fetchMore: fetchMore,
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColor.royalBlue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 12,
                                                              horizontal: 8),
                                                      shape:
                                                          const StadiumBorder(),
                                                      elevation: 0,
                                                    ),
                                                    icon: const Icon(
                                                        Icons.arrow_right),
                                                    label: const Text("Next"),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (showAppBar)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        width: ScreenUtil.screenWidth,
                                        decoration: BoxDecoration(
                                          color: (context.isLightMode()
                                                  ? Colors.white
                                                  : AppColor.vulcan)
                                              .withOpacity(0.95),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            )
                                          ],
                                          border: Border(
                                            bottom: BorderSide(
                                              color: context.isLightMode()
                                                  ? Colors.black12
                                                  : Colors.white10,
                                            ),
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(16),
                                            bottomRight: Radius.circular(16),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            top: barHeight,
                                            left: 3,
                                            right: 3,
                                          ),
                                          child: SizedBox(
                                            height: kToolbarHeight,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: Sizes
                                                                    .dimen_10,
                                                                right: Sizes
                                                                    .dimen_8),
                                                        child: ScaleAnim(
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .arrow_back_outlined,
                                                            size:
                                                                Sizes.dimen_22,
                                                          ),
                                                        ),
                                                      ),
                                                      ValueListenableBuilder(
                                                        builder: (context,
                                                            String value, _) {
                                                          return Text(
                                                            formatChapterTitle(
                                                                value),
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: Sizes
                                                                  .dimen_20.sp,
                                                            ),
                                                          );
                                                        },
                                                        valueListenable:
                                                            chapterName,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                                          Routes.mangaInfo,
                                                          ModalRoute
                                                              .withName(Routes
                                                                  .homeRoute),
                                                          arguments: newestMMdl.Datum(
                                                              title: widget
                                                                  .chapterList
                                                                  .mangaTitle,
                                                              mangaUrl: widget
                                                                  .chapterList
                                                                  .mangaUrl,
                                                              imageUrl: widget
                                                                  .chapterList
                                                                  .mangaImage,
                                                              mangaSource: widget
                                                                  .chapterList
                                                                  .mangaSource));
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Icon(
                                                              Icons.menu,
                                                              size: Sizes
                                                                  .dimen_24,
                                                              color: context
                                                                      .isLightMode()
                                                                  ? AppColor
                                                                      .vulcan
                                                                  : Colors
                                                                      .white),
                                                        ),
                                                        // Chapter picker for quick jump
                                                        GestureDetector(
                                                          onTap: () async {
                                                            final list = mangaReader
                                                                    .data
                                                                    .chapterList ??
                                                                [];
                                                            if (list.isEmpty) {
                                                              getItInstance<
                                                                      ToastServiceImpl>()
                                                                  .showToast(
                                                                      "No chapters available.",
                                                                      Toast
                                                                          .LENGTH_SHORT);
                                                              return;
                                                            }
                                                            final selected =
                                                                await showModalBottomSheet<
                                                                    ReaderChapterItem>(
                                                              context: context,
                                                              isScrollControlled:
                                                                  true,
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .cardColor,
                                                              builder: (ctx) {
                                                                return SafeArea(
                                                                  child:
                                                                      SizedBox(
                                                                    height: MediaQuery.of(ctx)
                                                                            .size
                                                                            .height *
                                                                        0.7,
                                                                    child: ListView
                                                                        .separated(
                                                                      itemBuilder:
                                                                          (c, i) {
                                                                        final item =
                                                                            list[i];
                                                                        return ListTile(
                                                                          title:
                                                                              Text(formatChapterTitle(item.chapterTitle)),
                                                                          subtitle:
                                                                              Text(item.dateUploaded ?? ''),
                                                                          onTap: () =>
                                                                              Navigator.of(ctx).pop(item),
                                                                        );
                                                                      },
                                                                      separatorBuilder: (_,
                                                                              __) =>
                                                                          const Divider(
                                                                              height: 1),
                                                                      itemCount:
                                                                          list.length,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );

                                                            if (selected !=
                                                                null) {
                                                              await doTheFunStuff(
                                                                theNextChapterTitle:
                                                                    selected
                                                                        .chapterTitle,
                                                                theNextChapterUrl:
                                                                    selected
                                                                        .chapterUrl,
                                                                fetchMore:
                                                                    fetchMore,
                                                              );
                                                            }
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Icon(
                                                              Icons.list_alt,
                                                              size: Sizes
                                                                  .dimen_24,
                                                              color: context
                                                                      .isLightMode()
                                                                  ? AppColor
                                                                      .vulcan
                                                                  : Colors
                                                                      .white,
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            })
                          : const Loading();
                    });
              }
              return Container();
            }),
      ),
    );
  }
}
