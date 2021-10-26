import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';

class MangaReader extends StatefulWidget {
  final ChapterList chapterList;

  const MangaReader({Key? key, required this.chapterList}) : super(key: key);

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<String> chapterName = ValueNotifier('');
  final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
  bool showAppBar = false;
  Future preLoadImages(List<String> listOfUrls) async {
    await Future.wait(
        listOfUrls.map((image) => cacheImage(context, image)).toList());
    isLoading.value = false;
  }

  Future cacheImage(BuildContext context, String image) =>
      precacheImage(CachedNetworkImageProvider(image), context);
  FetchMoreOptions toNewPageOptions(String newChapterUrl) {
    return FetchMoreOptions(
      variables: {'chapterUrl': newChapterUrl},
      updateQuery: (previousResultData, fetchMoreResultData) {
        return fetchMoreResultData;
      },
    );
  }

  @override
  void initState() {
    chapterName.value = widget.chapterList.chapterTitle;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? PreferredSize(
              preferredSize:
                  Size(MediaQuery.of(context).size.width, kToolbarHeight),
              child: TweenAnimationBuilder(
                curve: Curves.easeInOut,
                duration: Duration(seconds: 1),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double _val, Widget? child) {
                  return Opacity(
                    opacity: _val,
                    child: child,
                  );
                },
                child: AppBar(
                  automaticallyImplyLeading: false,
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back,
                        color: context.isLightMode()
                            ? Colors.black
                            : Colors.white),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(
                            Routes.mangaInfo,
                            arguments: newestMMdl.Datum(
                                title: widget.chapterList.mangaTitle,
                                mangaUrl: widget.chapterList.mangaUrl,
                                imageUrl: widget.chapterList.mangaImage));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.menu,
                            color: context.isLightMode()
                                ? AppColor.vulcan
                                : Colors.white),
                      ),
                    )
                  ],
                  title: ValueListenableBuilder(
                    builder: (context, String value, _) {
                      return Text(value
                              .replaceAll("-", " ")
                              .split(" ")[value.split("-").indexWhere(
                                      (element) => element == "chapter") +
                                  1]
                              .replaceFirst("c", "C") +
                          " " +
                          value.replaceAll("-", " ").split(" ")[value
                                  .split("-")
                                  .indexWhere(
                                      (element) => element == "chapter") +
                              2]);
                    },
                    valueListenable: chapterName,
                  ),
                ),
              ))
          : null,
      body: Query(
          options: QueryOptions(
            document: parseString(MANGA_READER),
            variables: {
              'chapterUrl': widget.chapterList.chapterUrl,
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
            dynamic mangaToRead = result.data!["getMangaReader"];

            if (mangaToRead != null) {
              GetMangaReader mangaReader = GetMangaReader.fromMap(mangaToRead);
              preLoadImages(mangaReader.data.images);
              return ValueListenableBuilder(
                  valueListenable: isLoading,
                  builder: (context, bool val, child) {
                    return !val
                        ? SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: LayoutBuilder(
                              builder: (context, contraint) {
                                return Container(
                                  child: Column(
                                    children: [
                                      ...List.generate(
                                          mangaReader.data.images.length, (index) {
                                        return GestureDetector(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                showAppBar = !showAppBar;
                                              });
                                              Future.delayed(Duration(seconds: 10),
                                                  () {
                                                if (!mounted) return;
                                                setState(() {
                                                  showAppBar = false;
                                                });
                                              });
                                            }
                                          },
                                          child: CachedNetworkImage(
                                            fadeInDuration:
                                                const Duration(microseconds: 100),
                                            imageUrl:
                                                mangaReader.data.images[index],
                                            fit: BoxFit.cover,
                                            placeholder: (ctx, string) {
                                              return Loading();
                                            },
                                          ),
                                        );
                                      }),
                                     contraint.biggest.height < ScreenUtil.screenHeight? Container(): GestureDetector(
                                        onTap: () async {
                                          if (!(int.tryParse(mangaReader
                                              .data.chapter
                                              .replaceAll(
                                              RegExp(r'[^0-9]'), ''))! >=
                                              mangaReader.data.chapterList!.length +
                                                  1)) {
                                            int currentChapter = int.parse(
                                                mangaReader.data.chapter.replaceAll(
                                                    RegExp(r'[^0-9]'), ''));
                                            String nextChapterUrl = widget
                                                .chapterList.chapterUrl
                                                .replaceAll(
                                                "${int.parse(widget.chapterList.chapterUrl.replaceAll(RegExp(r'[^0-9]'), ''))}",
                                                "${currentChapter + 1}");
                                            print(nextChapterUrl);

                                            final DatabaseHelper dbInstance =
                                            getItInstance<DatabaseHelper>();
                                            ChapterRead newChapter = ChapterRead(
                                                mangaUrl:
                                                widget.chapterList.mangaUrl,
                                                chapterUrl: nextChapterUrl);
                                            RecentlyRead recentlyRead = RecentlyRead(
                                                title:
                                                widget.chapterList.mangaTitle,
                                                mangaUrl:
                                                widget.chapterList.mangaUrl,
                                                imageUrl:
                                                widget.chapterList.mangaImage,
                                                chapterUrl: nextChapterUrl,
                                                chapterTitle: widget
                                                    .chapterList.chapterTitle
                                                    .replaceAll(
                                                    "${int.parse(widget.chapterList.chapterUrl.replaceAll(RegExp(r'[^0-9]'), ''))}",
                                                    "${currentChapter + 1}"),
                                                mostRecentReadDate:
                                                DateTime.now().toString());
                                            chapterName.value =
                                                recentlyRead.chapterTitle;
                                            List<RecentlyRead> recents = context
                                                .read<RecentsCubit>()
                                                .state
                                                .recents;
                                            List<ChapterRead> chaptersRead = context
                                                .read<ChaptersReadCubit>()
                                                .state
                                                .chaptersRead;
                                            List<RecentlyRead> withoutCurrentRead =
                                            recents
                                                .where((element) =>
                                            element.mangaUrl !=
                                                recentlyRead.mangaUrl)
                                                .toList();
                                            List<ChapterRead>
                                            withoutCurrentChapter = chaptersRead
                                                .where((element) =>
                                            element.chapterUrl !=
                                                newChapter.chapterUrl)
                                                .toList();

                                            context
                                                .read<RecentsCubit>()
                                                .setResults([
                                              ...withoutCurrentRead,
                                              recentlyRead
                                            ]);
                                            context
                                                .read<ChaptersReadCubit>()
                                                .setResults([
                                              ...withoutCurrentChapter,
                                              newChapter
                                            ]);
                                            await fetchMore!(
                                                toNewPageOptions(nextChapterUrl));
                                            await dbInstance
                                                .updateOrInsertChapterRead(
                                                newChapter);

                                            await dbInstance
                                                .updateOrInsertRecentlyRead(
                                                recentlyRead);
                                          }
                                        },
                                        child: Container(
                                          child: ValueListenableBuilder(
                                              valueListenable: isLoading,
                                              builder: (context, bool loading, _) {
                                                return !loading
                                                    ? Padding(
                                                  padding:
                                                  const EdgeInsets.all(
                                                      8.0),
                                                  child: !(int.tryParse(
                                                      mangaReader.data
                                                          .chapter
                                                          .replaceAll(
                                                          RegExp(
                                                              r'[^0-9]'),
                                                          ''))! >=
                                                      mangaReader
                                                          .data
                                                          .chapterList!
                                                          .length +
                                                          1)
                                                      ? ClipRRect(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        10.0),
                                                    child: Container(
                                                      color: context
                                                          .isLightMode()
                                                          ? AppColor
                                                          .vulcan
                                                          : Colors
                                                          .white,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: Sizes
                                                                .dimen_140
                                                                .w,
                                                            height: Sizes
                                                                .dimen_50
                                                                .h,
                                                            child: mangaReader !=
                                                                null
                                                                ? CachedNetworkImage(
                                                              imageUrl:
                                                              mangaReader.data.images![1],
                                                              fit:
                                                              BoxFit.cover,
                                                              placeholder:
                                                                  (ctx, string) {
                                                                return Loading();
                                                              },
                                                            )
                                                                : Container(),
                                                          ),
                                                          Container(
                                                            margin: EdgeInsets.only(
                                                                left: Sizes
                                                                    .dimen_40
                                                                    .w),
                                                            child: Text(
                                                              "Next chapter ${int.parse(mangaReader.data.chapter.replaceAll(RegExp(r'[^0-9]'), '')) + 1}",
                                                              style: TextStyle(
                                                                  fontWeight: FontWeight
                                                                      .bold,
                                                                  color: context.isLightMode()
                                                                      ? Colors.white
                                                                      : Colors.black),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                      : Text("Last Chapter"),
                                                )
                                                    : Container();
                                              }),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }
                            ),
                          )
                        : Loading();
                  });
            }
            return Container();
          }),
    );
  }
}
