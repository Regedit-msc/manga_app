import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
  late TransformationController controller;
  bool showAppBar = false;

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
    await Future.wait(listOfUrls.map((image) => cacheImage(context, image)));
    if (mounted) isLoading.value = false;
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
    controller = TransformationController();
    _scrollController.addListener(scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    chapterName.dispose();
    isLoading.dispose();
    controller.dispose();
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

  Widget checkLast(List<ReaderChapterItem>? chapterList, String chapter,
      GetMangaReader mangaReader) {
    int? currentChapter = extractChapterNumber(mangaReader.data.chapter);
    if (currentChapter == null) {
      // Return empty widget if can't parse current chapter
      return const SizedBox.shrink();
    }

    int nextChapter = currentChapter + 1;

    // Check if chapterList exists and has items
    if (mangaReader.data.chapterList == null ||
        mangaReader.data.chapterList!.isEmpty) {
      return const SizedBox.shrink();
    }

    int? theLastChapter =
        extractChapterNumber(mangaReader.data.chapterList![0].chapterTitle);
    if (theLastChapter == null) {
      // Return empty widget if can't parse last chapter
      return const SizedBox.shrink();
    }
    if (currentChapter < theLastChapter) {
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
                  imageUrl: mangaReader.data.images[1],
                  fit: BoxFit.cover,
                  placeholder: (ctx, string) => const Loading(),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: Sizes.dimen_40.w),
                child: Text(
                  "Next chapter $nextChapter",
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
    } else if (currentChapter == theLastChapter) {
      return const Text("Last Chapter");
    }

    return Container();
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
                                  ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        mangaReader.data.images.length + 1,
                                    itemBuilder: (context, idx) {
                                      if (idx <
                                          mangaReader.data.images.length) {
                                        final index = idx;
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
                                                tapDownDetails!.localPosition;
                                            final x =
                                                -position.dx * (scale - 1);
                                            final y =
                                                -position.dy * (scale - 1);

                                            final zoomed = Matrix4.identity()
                                              ..translate(x, y)
                                              ..scale(scale);
                                            final value =
                                                controller.value.isIdentity()
                                                    ? zoomed
                                                    : Matrix4.identity();
                                            controller.value = value;
                                          },
                                          onDoubleTapDown: (details) =>
                                              tapDownDetails = details,
                                          child: InteractiveViewer(
                                            transformationController:
                                                controller,
                                            clipBehavior: Clip.none,
                                            panEnabled: true,
                                            child: CachedNetworkImage(
                                              fadeInDuration: const Duration(
                                                  microseconds: 100),
                                              imageUrl: mangaReader
                                                  .data.images[index],
                                              fit: BoxFit.fitWidth,
                                              placeholder: (ctx, string) {
                                                return Container(
                                                    height:
                                                        ScreenUtil.screenHeight,
                                                    width:
                                                        ScreenUtil.screenWidth,
                                                    child:
                                                        NoAnimationLoading());
                                              },
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
                                                int? theInitialChapter =
                                                    extractChapterNumber(widget
                                                        .chapterList
                                                        .chapterTitle);
                                                int? theCurrentChapter =
                                                    extractChapterNumber(
                                                        mangaReader
                                                            .data.chapter);

                                                if (theInitialChapter == null ||
                                                    theCurrentChapter == null) {
                                                  // Can't parse chapter numbers, skip navigation
                                                  return;
                                                }

                                                int theNextChapter =
                                                    theCurrentChapter + 1;
                                                String theNextChapterUrl = widget
                                                    .chapterList.chapterUrl
                                                    .replaceAll(
                                                        theInitialChapter
                                                            .toString(),
                                                        theNextChapter
                                                            .toString());
                                                String theNextChapterTitle =
                                                    widget.chapterList
                                                        .chapterTitle
                                                        .replaceAll(
                                                            theInitialChapter
                                                                .toString(),
                                                            theNextChapter
                                                                .toString());
                                                int? theLastChapter =
                                                    extractChapterNumber(
                                                        mangaReader
                                                                .data
                                                                .chapterList?[0]
                                                                .chapterTitle ??
                                                            '');

                                                if (theLastChapter == null) {
                                                  // Can't parse last chapter number
                                                  return;
                                                }

                                                if (theCurrentChapter <
                                                    theLastChapter) {
                                                  await doTheFunStuff(
                                                      theNextChapterTitle:
                                                          theNextChapterTitle,
                                                      theNextChapterUrl:
                                                          theNextChapterUrl,
                                                      fetchMore: fetchMore);
                                                }
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
                                  Positioned(
                                      bottom: 0,
                                      child: showAppBar
                                          ? Container(
                                              color: context.isLightMode()
                                                  ? Colors.white
                                                  : AppColor.vulcan,
                                              width: ScreenUtil.screenWidth,
                                              height: kToolbarHeight,
                                              child: Row(
                                                children: [
                                                  const Expanded(
                                                      child: SizedBox.shrink()),
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        ScaleAnim(
                                                            onTap: () async {
                                                              int?
                                                                  theInitialChapter =
                                                                  extractChapterNumber(widget
                                                                      .chapterList
                                                                      .chapterTitle);
                                                              int?
                                                                  theCurrentChapter =
                                                                  extractChapterNumber(
                                                                      mangaReader
                                                                          .data
                                                                          .chapter);

                                                              if (theInitialChapter ==
                                                                      null ||
                                                                  theCurrentChapter ==
                                                                      null) {
                                                                // Can't parse chapter numbers, skip navigation
                                                                return;
                                                              }

                                                              int thePreviousChapter =
                                                                  theCurrentChapter -
                                                                      1;
                                                              String thePreviousChapterUrl = widget
                                                                  .chapterList
                                                                  .chapterUrl
                                                                  .replaceAll(
                                                                      theInitialChapter
                                                                          .toString(),
                                                                      thePreviousChapter
                                                                          .toString());
                                                              String thePreviousChapterTitle = widget
                                                                  .chapterList
                                                                  .chapterTitle
                                                                  .replaceAll(
                                                                      theInitialChapter
                                                                          .toString(),
                                                                      thePreviousChapter
                                                                          .toString());
                                                              int?
                                                                  theFirstChapter =
                                                                  extractChapterNumber(mangaReader
                                                                          .data
                                                                          .chapterList?[mangaReader.data.chapterList!.length -
                                                                              1]
                                                                          .chapterTitle ??
                                                                      '');

                                                              if (theFirstChapter ==
                                                                  null) {
                                                                // Can't parse first chapter number
                                                                return;
                                                              }

                                                              if (theCurrentChapter >
                                                                  theFirstChapter) {
                                                                await doTheFunStuff(
                                                                    theNextChapterUrl:
                                                                        thePreviousChapterUrl,
                                                                    theNextChapterTitle:
                                                                        thePreviousChapterTitle,
                                                                    fetchMore:
                                                                        fetchMore);
                                                              }
                                                            },
                                                            child: Icon(
                                                                Icons
                                                                    .arrow_left,
                                                                size: Sizes
                                                                    .dimen_50)),
                                                        SizedBox(
                                                          width: Sizes.dimen_20,
                                                        ),
                                                        ScaleAnim(
                                                          onTap: () async {
                                                            int?
                                                                theInitialChapter =
                                                                extractChapterNumber(widget
                                                                    .chapterList
                                                                    .chapterTitle);
                                                            int?
                                                                theCurrentChapter =
                                                                extractChapterNumber(
                                                                    mangaReader
                                                                        .data
                                                                        .chapter);

                                                            if (theInitialChapter ==
                                                                    null ||
                                                                theCurrentChapter ==
                                                                    null) {
                                                              // Can't parse chapter numbers, skip navigation
                                                              return;
                                                            }

                                                            int theNextChapter =
                                                                theCurrentChapter +
                                                                    1;
                                                            String theNextChapterUrl = widget
                                                                .chapterList
                                                                .chapterUrl
                                                                .replaceAll(
                                                                    theInitialChapter
                                                                        .toString(),
                                                                    theNextChapter
                                                                        .toString());
                                                            String theNextChapterTitle = widget
                                                                .chapterList
                                                                .chapterTitle
                                                                .replaceAll(
                                                                    theInitialChapter
                                                                        .toString(),
                                                                    theNextChapter
                                                                        .toString());
                                                            int?
                                                                theLastChapter =
                                                                extractChapterNumber(
                                                                    mangaReader
                                                                            .data
                                                                            .chapterList?[0]
                                                                            .chapterTitle ??
                                                                        '');

                                                            if (theLastChapter ==
                                                                null) {
                                                              // Can't parse last chapter number
                                                              return;
                                                            }

                                                            if (theCurrentChapter <
                                                                theLastChapter) {
                                                              await doTheFunStuff(
                                                                  theNextChapterTitle:
                                                                      theNextChapterTitle,
                                                                  theNextChapterUrl:
                                                                      theNextChapterUrl,
                                                                  fetchMore:
                                                                      fetchMore);
                                                            }
                                                          },
                                                          child: Icon(
                                                              Icons.arrow_right,
                                                              size: Sizes
                                                                  .dimen_50),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          : Container()),
                                  Positioned(
                                      top: 0,
                                      child: showAppBar
                                          ? Container(
                                              color: context.isLightMode()
                                                  ? Colors.white
                                                  : AppColor.vulcan,
                                              width: ScreenUtil.screenWidth,
                                              height:
                                                  kToolbarHeight + barHeight,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3.0),
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                      top: barHeight),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Padding(
                                                              padding: EdgeInsets.only(
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
                                                                  size: Sizes
                                                                      .dimen_22,
                                                                ),
                                                              ),
                                                            ),
                                                            ValueListenableBuilder(
                                                              builder: (context,
                                                                  String value,
                                                                  _) {
                                                                return Text(
                                                                  formatChapterTitle(
                                                                      value),
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize: Sizes
                                                                        .dimen_20
                                                                        .sp,
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
                                                                Routes
                                                                    .mangaInfo,
                                                                ModalRoute.withName(
                                                                    Routes
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
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Icon(
                                                                    Icons.menu,
                                                                    size: Sizes
                                                                        .dimen_24,
                                                                    color: context.isLightMode()
                                                                        ? AppColor
                                                                            .vulcan
                                                                        : Colors
                                                                            .white),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container()),
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
