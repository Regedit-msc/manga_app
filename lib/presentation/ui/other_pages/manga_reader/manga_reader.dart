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
import 'package:webcomic/presentation/ui/loading/loading.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MangaReader extends StatefulWidget {
  final ChapterList chapterList;

  const MangaReader({Key? key, required this.chapterList}) : super(key: key);

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  // TODO: INTRO TO READER
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<String> chapterName = ValueNotifier('');
  TapDownDetails? tapDownDetails;
  late TransformationController controller;
  final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
  bool showAppBar = false;
  Future preLoadImages(List<String> listOfUrls) async {
    await Future.wait(
        listOfUrls.map((image) => cacheImage(context, image)).toList());
   if(mounted){
     isLoading.value = false;
   }
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
    // doSetup();
    controller = TransformationController();
    _scrollController.addListener(scrollListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive,
    );
    super.initState();
  }

  @override
  void dispose() {
    doCleanUp();
    chapterName.dispose();
    isLoading.dispose();
    controller.dispose();
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    print("Dispose");


    super.dispose();
  }

  void doCleanUp(){
   Future.delayed(Duration(milliseconds: 500), (){
     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
   });
  }


  void scrollListener(){
    if(mounted){
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
          setState(() {
            showAppBar = true;
          });


      } else {
        if(showAppBar){
          setState(() {
            showAppBar = false;
          });

        }
      }
    }
  }

  void doSetup() {
    if (mounted) {
      Future.delayed(Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() {
          showAppBar = true;
        });
      });
      Future.delayed(Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          showAppBar = false;
        });
      });
    }
  }

  Future<void> doTheFunStuff(
      {String theNextChapterUrl = '',
      String theNextChapterTitle = "",
      dynamic fetchMore}) async {
    final DatabaseHelper dbInstance = getItInstance<DatabaseHelper>();
    ChapterRead newChapter = ChapterRead(
        mangaUrl: widget.chapterList.mangaUrl, chapterUrl: theNextChapterUrl);
    RecentlyRead recentlyRead = RecentlyRead(
        title: widget.chapterList.mangaTitle,
        mangaUrl: widget.chapterList.mangaUrl,
        imageUrl: widget.chapterList.mangaImage,
        chapterUrl: theNextChapterUrl,
        chapterTitle: theNextChapterTitle,
        mostRecentReadDate: DateTime.now().toString());
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

  Widget checkLast(
      List<String>? chapterList, String chapter, GetMangaReader mangaReader) {
    int currentChapter = int.parse(mangaReader.data.chapter
        .replaceAll("-", " ")
        .split(" ")[mangaReader.data.chapter
            .replaceAll("-", " ")
            .split(" ")
            .indexWhere((element) => element == "chapter") +
        1]);

    int nextChapter = currentChapter + 1;
    int theLastChapter = int.parse(mangaReader
        .data
        .chapterList![
    0]
        .replaceAll("-", " ")
        .split(" ")[mangaReader
        .data
        .chapterList![0]
        .replaceAll("-", " ")
        .split(" ")
        .indexWhere((element) => element == "chapter") +
        1]);
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
                child: mangaReader != null
                    ? CachedNetworkImage(
                  imageUrl: mangaReader.data.images![1],
                  fit: BoxFit.cover,
                  placeholder: (ctx, string) {
                    return Loading();
                  },
                )
                    : Container(),
              ),
              Container(
                margin: EdgeInsets.only(left: Sizes.dimen_40.w),
                child: Text(
                  "Next chapter $nextChapter",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.isLightMode()
                          ? Colors.white
                          : Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (currentChapter == theLastChapter) {
      return Text("Last Chapter");
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              if(context.read<SettingsCubit>().state.settings.preloadImages){
                print("Preload");
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
                                SingleChildScrollView(
                                  controller: _scrollController,
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    children: [
                                      ...List.generate(
                                          mangaReader.data.images.length,
                                          (index) {
                                        return GestureDetector(
                                          onTap: () {
                                            if (mounted) {
                                              setState(() {
                                                showAppBar = !showAppBar;
                                              });
                                            }
                                          },
                                          onDoubleTap: (){
                                            final double scale = 2;
                                            final  position = tapDownDetails!.localPosition;
                                            final x = -position.dx * (scale -1);
                                            final y = -position.dy * (scale -1);

                                            final zoomed = Matrix4.identity()
                                              ..translate(x, y)
                                              ..scale(scale);
                                            final value = controller.value.isIdentity()?zoomed :Matrix4.identity();
                                           controller.value = value;
                                          },
                                          onDoubleTapDown: (details) => tapDownDetails = details,
                                          child: InteractiveViewer(
                                            transformationController: controller,
                                            clipBehavior: Clip.none,
                                            // scaleEnabled: true,
                                            panEnabled: true,
                                            child: FittedBox(
                                              child: CachedNetworkImage(
                                                fadeInDuration: const Duration(
                                                    microseconds: 100),
                                                imageUrl: mangaReader
                                                    .data.images[index],
                                                fit: BoxFit.cover,
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
                                          ),
                                        );
                                      }),
                                      contraint.biggest.height <
                                              ScreenUtil.screenHeight
                                          ? Container()
                                          : GestureDetector(
                                              onTap: () async {
                                                int theInitialChapter =
                                                    int.parse(widget
                                                        .chapterList
                                                        .chapterTitle
                                                        .replaceAll("-", " ")
                                                        .split(" ")[widget
                                                            .chapterList
                                                            .chapterTitle
                                                            .replaceAll(
                                                                "-", " ")
                                                            .split(" ")
                                                            .indexWhere(
                                                                (element) =>
                                                                    element ==
                                                                    "chapter") +
                                                        1]);
                                                int theCurrentChapter =
                                                    int.parse(mangaReader
                                                        .data.chapter
                                                        .replaceAll("-", " ")
                                                        .split(" ")[mangaReader
                                                            .data.chapter
                                                            .replaceAll(
                                                                "-", " ")
                                                            .split(" ")
                                                            .indexWhere(
                                                                (element) =>
                                                                    element ==
                                                                    "chapter") +
                                                        1]);
                                                int theNextChapter =
                                                    theCurrentChapter + 1;
                                                String theNextChapterUrl =
                                                    widget
                                                        .chapterList.chapterUrl
                                                        .replaceAll(
                                                            theInitialChapter
                                                                .toString(),
                                                            theNextChapter
                                                                .toString());
                                                print(theNextChapterUrl);
                                                String theNextChapterTitle =
                                                    widget.chapterList
                                                        .chapterTitle
                                                        .replaceAll(
                                                            theInitialChapter
                                                                .toString(),
                                                            theNextChapter
                                                                .toString());
                                                int theLastChapter = int.parse(mangaReader
                                                    .data
                                                    .chapterList![
                                                0]
                                                    .replaceAll("-", " ")
                                                    .split(" ")[mangaReader
                                                    .data
                                                    .chapterList![0]
                                                    .replaceAll("-", " ")
                                                    .split(" ")
                                                    .indexWhere((element) => element == "chapter") +
                                                    1]);


                                                  ///  if the current chapter is lesser than the last chapter
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
                                              child: Container(
                                                child: ValueListenableBuilder(
                                                    valueListenable:
                                                        isLoading,
                                                    builder: (context,
                                                        bool loading, _) {
                                                      return !loading
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      8.0),
                                                              child: checkLast(
                                                                  mangaReader
                                                                      .data
                                                                      .chapterList,
                                                                  mangaReader
                                                                      .data
                                                                      .chapter,
                                                                  mangaReader))
                                                          : Container();
                                                    }),
                                              ),
                                            )
                                    ],
                                  ),
                                ),
                               Positioned(
                                   bottom: 0,
                                   child:  showAppBar
                                       ? Container(
                                         color:context.isLightMode()? Colors.white: AppColor.vulcan,
                                         width: ScreenUtil.screenWidth,
                                         height: kToolbarHeight,
                                         child: Row(
                                           children: [
                                             Expanded(
                                                 child: Row(children: [])),
                                             Expanded(
                                               child: Row(
                                                 mainAxisAlignment:
                                                 MainAxisAlignment.center,
                                                 crossAxisAlignment:
                                                 CrossAxisAlignment.center,
                                                 children: [
                                                   ScaleAnim(
                                                       onTap: () async{
                                                         int theInitialChapter =
                                                         int.parse(widget
                                                             .chapterList
                                                             .chapterTitle
                                                             .replaceAll("-", " ")
                                                             .split(" ")[widget
                                                             .chapterList
                                                             .chapterTitle
                                                             .replaceAll(
                                                             "-", " ")
                                                             .split(" ")
                                                             .indexWhere(
                                                                 (element) =>
                                                             element ==
                                                                 "chapter") +
                                                             1]);
                                                         int theCurrentChapter =
                                                         int.parse(mangaReader
                                                             .data.chapter
                                                             .replaceAll("-", " ")
                                                             .split(" ")[mangaReader
                                                             .data.chapter
                                                             .replaceAll(
                                                             "-", " ")
                                                             .split(" ")
                                                             .indexWhere(
                                                                 (element) =>
                                                             element ==
                                                                 "chapter") +
                                                             1]);
                                                         int thePreviousChapter =
                                                             theCurrentChapter - 1;
                                                         String thePreviousChapterUrl =
                                                         widget
                                                             .chapterList.chapterUrl
                                                             .replaceAll(
                                                             theInitialChapter
                                                                 .toString(),
                                                             thePreviousChapter
                                                                 .toString());
                                                         String thePreviousChapterTitle =
                                                         widget.chapterList
                                                             .chapterTitle
                                                             .replaceAll(
                                                             theInitialChapter
                                                                 .toString(),
                                                             thePreviousChapter
                                                                 .toString());
                                                         int theFirstChapter = int.parse(mangaReader
                                                             .data
                                                             .chapterList![
                                                         mangaReader.data.chapterList!.length -
                                                             1]
                                                             .replaceAll("-", " ")
                                                             .split(" ")[mangaReader
                                                             .data
                                                             .chapterList![mangaReader
                                                             .data
                                                             .chapterList!
                                                             .length -
                                                             1]
                                                             .replaceAll("-", " ")
                                                             .split(" ")
                                                             .indexWhere((element) => element == "chapter") +
                                                             1]);
                                                         if(theCurrentChapter > theFirstChapter){
                                                           await doTheFunStuff(theNextChapterUrl: thePreviousChapterUrl, theNextChapterTitle: thePreviousChapterTitle, fetchMore: fetchMore);
                                                         }
                                                       },

                                                       child: Icon(Icons.arrow_left,

                                                           size: Sizes.dimen_50
                                                       )),
                                                   SizedBox(
                                                     width: Sizes.dimen_20,
                                                   ),
                                                   ScaleAnim(
                                                     onTap: () async {
                                                       int theInitialChapter =
                                                       int.parse(widget
                                                           .chapterList
                                                           .chapterTitle
                                                           .replaceAll("-", " ")
                                                           .split(" ")[widget
                                                           .chapterList
                                                           .chapterTitle
                                                           .replaceAll(
                                                           "-", " ")
                                                           .split(" ")
                                                           .indexWhere(
                                                               (element) =>
                                                           element ==
                                                               "chapter") +
                                                           1]);
                                                       int theCurrentChapter =
                                                       int.parse(mangaReader
                                                           .data.chapter
                                                           .replaceAll("-", " ")
                                                           .split(" ")[mangaReader
                                                           .data.chapter
                                                           .replaceAll(
                                                           "-", " ")
                                                           .split(" ")
                                                           .indexWhere(
                                                               (element) =>
                                                           element ==
                                                               "chapter") +
                                                           1]);
                                                       int theNextChapter =
                                                           theCurrentChapter + 1;
                                                       String theNextChapterUrl =
                                                       widget
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
                                                       int theLastChapter = int.parse(mangaReader
                                                           .data
                                                           .chapterList![
                                                       0]
                                                           .replaceAll("-", " ")
                                                           .split(" ")[mangaReader
                                                           .data
                                                           .chapterList![0]
                                                           .replaceAll("-", " ")
                                                           .split(" ")
                                                           .indexWhere((element) => element == "chapter") +
                                                           1]);
                                                       ///  if the current chapter is lesser than the last chapter
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
                                                     child: Icon(Icons
                                                         .arrow_right,
                                                         size: Sizes.dimen_50
                                                     ),
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
                                    child:  showAppBar
                                        ? Container(
                                            color:context.isLightMode()? Colors.white: AppColor.vulcan,
                                            width: ScreenUtil.screenWidth,
                                            height: kToolbarHeight,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                               Expanded(
                                                 child: Row(
                                                   children: [
                                                   Padding(
                                                     padding:  EdgeInsets.only(left: Sizes.dimen_10, right: Sizes.dimen_8),
                                                     child: ScaleAnim(
                                                       onTap:(){
                                                         Navigator.pop(context);
                                                       },
                                                       child: Icon(Icons.arrow_back_outlined,
                                                       size: Sizes.dimen_22,

                                                       ),
                                                     ),
                                                   ),
                                                   ValueListenableBuilder(
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
                                                               2],

                                                       style: TextStyle(
                                                         fontWeight: FontWeight.bold,
                                                         fontSize: Sizes.dimen_20.sp,
                                                       ),

                                                       );
                                                     },
                                                     valueListenable: chapterName,
                                                   ),
                                                 ],),
                                               ),
                                                Expanded(
                                                  flex: 1,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      // Navigator.of(context).pushReplacementNamed(
                                                      //     Routes.mangaInfo,
                                                      //     arguments: newestMMdl.Datum(
                                                      //         title: widget.chapterList.mangaTitle,
                                                      //         mangaUrl: widget.chapterList.mangaUrl,
                                                      //         imageUrl: widget.chapterList.mangaImage));
                                                      Navigator.of(context).pushNamedAndRemoveUntil(  Routes.mangaInfo, ModalRoute.withName(  Routes.homeRoute), arguments: newestMMdl.Datum(
                                                          title: widget.chapterList.mangaTitle,
                                                          mangaUrl: widget.chapterList.mangaUrl,
                                                          imageUrl: widget.chapterList.mangaImage));
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.all(8.0),
                                                          child: Icon(Icons.menu,
                                                              size: Sizes.dimen_24,
                                                              color: context.isLightMode()
                                                                  ? AppColor.vulcan
                                                                  : Colors.white),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )

                                              ],),
                                            ),
                                        )
                                        : Container()),
                              ],
                            );
                          })
                        : Loading();
                  });
            }
            return Container();
          }),
    );
  }
}
