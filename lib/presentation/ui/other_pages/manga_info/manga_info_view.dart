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
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';

class MangaInfo extends StatefulWidget {
  final Datum mangaDetails;
  const MangaInfo({Key? key, required this.mangaDetails}) : super(key: key);

  @override
  _MangaInfoState createState() => _MangaInfoState();
}

class _MangaInfoState extends State<MangaInfo> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
    ));
    return Scaffold(
      body: Query(
          options: QueryOptions(
            document: parseString(GET_MANGA_INFO),
            variables: {
              'mangaUrl': widget.mangaDetails.mangaUrl ?? '',
            },
            pollInterval: null,
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            GetMangaInfo? mangaInfo;

            if (result.isNotLoading && !result.hasException) {
              final resultData = result.data!["getMangaInfo"];
              print(" result data $resultData");
              mangaInfo = GetMangaInfo.fromMap(resultData);
            }
            return DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, value) {
                  return [
                    SliverAppBar(
                      expandedHeight: ScreenUtil.screenHeight / 2,
                      bottom: TabBar(
                        indicatorColor: AppColor.royalBlue,
                        tabs: [
                          Tab(
                            child: Text(
                              "CHAPTERS",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Sizes.dimen_16.sp),
                            ),
                          ),
                          Tab(
                            child: Text(
                              "RECOMMENDED",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: Sizes.dimen_16.sp),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final DatabaseHelper dbInstance =
                                    getItInstance<DatabaseHelper>();
                                List<Subscribe> subs =
                                    context.read<SubsCubit>().state.subs;
                                Subscribe newSub = Subscribe(
                                    imageUrl:
                                        widget.mangaDetails.imageUrl ?? '',
                                    dateSubscribed: DateTime.now().toString(),
                                    title: widget.mangaDetails.title ?? '',
                                    mangaUrl:
                                        widget.mangaDetails.mangaUrl ?? '');
                                int indexOfCurrentMangaIfSubbed =
                                    subs.indexWhere((element) =>
                                        element.mangaUrl ==
                                        widget.mangaDetails.mangaUrl);
                                if (indexOfCurrentMangaIfSubbed != -1) {
                                  subs.removeWhere((element) =>
                                      element.mangaUrl ==
                                      widget.mangaDetails.mangaUrl);
                                  context.read<SubsCubit>().setSubs(subs);
                                } else {
                                  context
                                      .read<SubsCubit>()
                                      .setSubs([...subs, newSub]);
                                }
                                await getItInstance<GQLRawApiServiceImpl>()
                                    .subscribe(widget.mangaDetails.title ?? '');
                                await dbInstance
                                    .updateOrInsertSubscription(newSub);
                              },
                              child: BlocBuilder<SubsCubit, SubsState>(
                                  builder: (context, subsState) {
                                int indexOfCurrentMangaIfSubbed = subsState.subs
                                    .indexWhere((element) =>
                                        element.mangaUrl ==
                                        widget.mangaDetails.mangaUrl);
                                return Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: indexOfCurrentMangaIfSubbed != -1
                                      ? Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Sizes.dimen_20.sp),
                                              color: Colors.white),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'UNSUBSCRIBE',
                                              style: TextStyle(
                                                  fontSize: Sizes.dimen_10.sp,
                                                  color: AppColor.vulcan,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Sizes.dimen_20.sp),
                                              color: Colors.white),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'SUBSCRIBE',
                                              style: TextStyle(
                                                  fontSize: Sizes.dimen_10.sp,
                                                  color: AppColor.vulcan,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                );
                              }),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.info),
                            )
                          ],
                        )
                      ],
                      elevation: 0.0,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      // floating: true,
                      // expandedHeight: Sizes.dimen_140.h,
                      flexibleSpace:
                          LayoutBuilder(builder: (context, constraints) {
                        return Stack(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                        sigmaY: 1.0, sigmaX: 1.0),
                                    child: CachedNetworkImage(
                                        imageUrl:
                                            widget.mangaDetails.imageUrl ?? '',
                                        fit: BoxFit.cover,
                                        colorBlendMode: BlendMode.darken),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: Sizes.dimen_10),
                              child: constraints.biggest.height >
                                      Sizes.dimen_160.h
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          top: Sizes.dimen_10.h),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                                mangaInfo!.data != null
                                                    ? mangaInfo.data.summary
                                                                .length >
                                                            200
                                                        ? mangaInfo.data.summary
                                                                .substring(
                                                                    0, 200) +
                                                            "..."
                                                        : mangaInfo.data.summary
                                                    : '',
                                                style: ThemeText.whiteBodyText2
                                                    ?.copyWith(
                                                  fontSize: Sizes.dimen_14.sp,
                                                )),
                                          ),
                                          SizedBox(
                                            height: Sizes.dimen_4.h,
                                          ),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  widget.mangaDetails.title ?? "",
                                                  style: ThemeText.whiteBodyText2
                                                      ?.copyWith(
                                                          fontSize:
                                                              Sizes.dimen_20.sp,
                                                          fontWeight:
                                                              FontWeight.w900),
                                                ),
                                              ),
                                              SizedBox(
                                                width: Sizes.dimen_10.w,
                                              ),
                                              Text(
                                                mangaInfo.data.status ?? "",
                                                style: ThemeText.whiteBodyText2
                                                    ?.copyWith(
                                                        color:
                                                            AppColor.royalBlue,
                                                        fontSize:
                                                            Sizes.dimen_20.sp,
                                                        fontWeight:
                                                            FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: Sizes.dimen_4.h,
                                          ),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            physics: BouncingScrollPhysics(),
                                            child: Row(
                                              children: [
                                                ...List.generate(
                                                    mangaInfo!.data.genres
                                                        .length, (index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(Sizes
                                                                      .dimen_16
                                                                      .sp)),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Text(
                                                          mangaInfo!
                                                              .data
                                                              .genres[index]
                                                              .genre,
                                                          style: TextStyle(
                                                              color: AppColor
                                                                  .vulcan),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                })
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            height: Sizes.dimen_2.h,
                                          ),
                                          Text(
                                              "AUTHOR: " +
                                                  mangaInfo.data.author,
                                              style: ThemeText.whiteBodyText2
                                                  ?.copyWith(
                                                      fontSize:
                                                          Sizes.dimen_16.sp,
                                                      fontWeight:
                                                          FontWeight.w900)),
                                        ],
                                      ),
                                    )
                                  : Container(),
                            )
                          ],
                        );
                      }),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    ListView.builder(
                        itemCount: result.isLoading
                            ? 1
                            : mangaInfo != null
                                ? mangaInfo.data.chapterList.length
                                : 20,
                        itemBuilder: (ctx, index) {
                          if (result.hasException) {
                            return Text(result.exception.toString());
                          }

                          if (result.isLoading) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Loading chapters ... '),
                            ));
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: BlocBuilder<ChaptersReadCubit,
                                    ChaptersReadState>(
                                builder: (context, chapterReadState) {
                              return Container(
                                decoration: BoxDecoration(
                                    color: chapterReadState.chaptersRead
                                                .indexWhere((element) =>
                                                    element.chapterUrl ==
                                                    mangaInfo!
                                                        .data
                                                        .chapterList[index]
                                                        .chapterUrl) !=
                                            -1
                                        ? Color(0xff231942)
                                        : Colors.transparent),
                                child: ListTile(
                                  isThreeLine: true,
                                  onTap: () async {
                                    final DatabaseHelper dbInstance =
                                        getItInstance<DatabaseHelper>();
                                    ChapterRead newChapter = ChapterRead(
                                        mangaUrl:
                                            widget.mangaDetails.mangaUrl ??
                                                'none',
                                        chapterUrl: mangaInfo!.data
                                            .chapterList[index].chapterUrl);
                                    RecentlyRead recentlyRead = RecentlyRead(
                                        title: widget.mangaDetails.title ?? '',
                                        mangaUrl:
                                            widget.mangaDetails.mangaUrl ?? '',
                                        imageUrl:
                                            widget.mangaDetails.imageUrl ?? "",
                                        chapterUrl: mangaInfo
                                            .data.chapterList[index].chapterUrl,
                                        chapterTitle: mangaInfo.data
                                            .chapterList[index].chapterTitle,
                                        mostRecentReadDate:
                                            DateTime.now().toString());
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
                                    List<ChapterRead> withoutCurrentChapter =
                                        chaptersRead
                                            .where((element) =>
                                                element.chapterUrl !=
                                                newChapter.chapterUrl)
                                            .toList();

                                    context.read<RecentsCubit>().setResults(
                                        [...withoutCurrentRead, recentlyRead]);
                                    context
                                        .read<ChaptersReadCubit>()
                                        .setResults([
                                      ...withoutCurrentChapter,
                                      newChapter
                                    ]);
                                    await dbInstance
                                        .updateOrInsertChapterRead(newChapter);

                                    await dbInstance.updateOrInsertRecentlyRead(
                                        recentlyRead);
                                    Navigator.pushNamed(
                                        context, Routes.mangaReader,
                                        arguments: ChapterList(
                                            mangaImage:
                                                widget.mangaDetails.imageUrl ??
                                                    '',
                                            mangaTitle:
                                                widget.mangaDetails.title ?? '',
                                            mangaUrl:
                                                widget.mangaDetails.mangaUrl ??
                                                    '',
                                            chapterUrl: mangaInfo.data
                                                .chapterList[index].chapterUrl,
                                            chapterTitle: mangaInfo
                                                .data
                                                .chapterList[index]
                                                .chapterTitle,
                                            dateUploaded: mangaInfo
                                                .data
                                                .chapterList[index]
                                                .dateUploaded));
                                  },
                                  subtitle: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      mangaInfo!
                                          .data.chapterList[index].dateUploaded,
                                      style:
                                          TextStyle(color: Color(0xffF4E8C1)),
                                    ),
                                  ),
                                  leading: Container(
                                      padding: EdgeInsets.all(8),
                                      width: 100,
                                      child: CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                                widget.mangaDetails.imageUrl ??
                                                    ''),
                                      )),
                                  title: Text(mangaInfo
                                          .data.chapterList[index].chapterTitle
                                          .replaceAll("-", " ")
                                          .split(" ")[mangaInfo
                                                  .data
                                                  .chapterList[index]
                                                  .chapterTitle
                                                  .split("-")
                                                  .indexWhere((element) =>
                                                      element == "chapter") +
                                              1]
                                          .replaceFirst("c", "C") +
                                      " " +
                                      mangaInfo.data.chapterList[index].chapterTitle
                                              .replaceAll("-", " ")
                                              .split(" ")[
                                          mangaInfo.data.chapterList[index].chapterTitle.split("-").indexWhere((element) => element == "chapter") + 2]),
                                ),
                              );
                            }),
                          );
                        }),
                    Container(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 8.0,
                        children: List.generate(
                            mangaInfo!.data.recommendations.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(Routes.mangaInfo,
                                  arguments: newestMMdl.Datum(
                                      title: mangaInfo!
                                          .data.recommendations[index].title,
                                      mangaUrl: mangaInfo!
                                          .data.recommendations[index].mangaUrl,
                                      imageUrl: mangaInfo!.data
                                          .recommendations[index].mangaImage));
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: Sizes.dimen_60.h,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          Sizes.dimen_10.sp),
                                      child: CachedNetworkImage(
                                        imageUrl: mangaInfo!
                                                .data
                                                .recommendations[index]
                                                .mangaImage ??
                                            '',
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        placeholder: (context, url) => Center(
                                            child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: Sizes.dimen_4.h,
                                ),
                                Text(
                                  mangaInfo!.data.recommendations[index].title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
