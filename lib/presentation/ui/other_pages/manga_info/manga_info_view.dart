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
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';

class MangaInfo extends StatefulWidget {
  final Datum mangaDetails;
  const MangaInfo({Key? key, required this.mangaDetails}) : super(key: key);

  @override
  _MangaInfoState createState() => _MangaInfoState();
}

class _MangaInfoState extends State<MangaInfo> {
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
            pollInterval: const Duration(minutes: 20),
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            GetMangaInfo? mangaInfo;

            if (result.isNotLoading && !result.hasException) {
              final resultData = result.data!["getMangaInfo"];
              print(resultData);
              mangaInfo = GetMangaInfo.fromMap(resultData);
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  actions: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.add),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.info),
                    )
                  ],
                  elevation: 0.0,
                  pinned: true,
                  floating: true,
                  expandedHeight: Sizes.dimen_140.h,
                  flexibleSpace: LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ImageFiltered(
                                imageFilter:
                                    ImageFilter.blur(sigmaY: 2.0, sigmaX: 2.0),
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
                          padding: const EdgeInsets.only(left: Sizes.dimen_10),
                          child: constraints.biggest.height > Sizes.dimen_140.h
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                                            .substring(0, 200) +
                                                        "..."
                                                    : mangaInfo.data.summary
                                                : '',
                                            style: ThemeText.whiteBodyText2
                                                ?.copyWith(
                                              fontSize: Sizes.dimen_14.sp,
                                            )),
                                      ),
                                      SizedBox(
                                        height: Sizes.dimen_10.h,
                                      ),
                                      Text(
                                        widget.mangaDetails.title ?? "",
                                        style: ThemeText.whiteBodyText2
                                            ?.copyWith(
                                                fontSize: Sizes.dimen_20.sp,
                                                fontWeight: FontWeight.w900),
                                      ),
                                      SizedBox(
                                        height: Sizes.dimen_10.h,
                                      ),
                                      Text("AUTHOR: " + mangaInfo.data.author,
                                          style: ThemeText.whiteBodyText2
                                              ?.copyWith(
                                                  fontSize: Sizes.dimen_16.sp,
                                                  fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                )
                              : Container(),
                        )
                      ],
                    );
                  }),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, int index) {
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
                        child:
                            BlocBuilder<ChaptersReadCubit, ChaptersReadState>(
                                builder: (context, chapterReadState) {
                          return Container(
                            decoration: BoxDecoration(
                                color: chapterReadState.chaptersRead.indexWhere(
                                            (element) =>
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
                                        widget.mangaDetails.mangaUrl ?? 'none',
                                    chapterUrl: mangaInfo!
                                        .data.chapterList[index].chapterUrl);
                                RecentlyRead recentlyRead = RecentlyRead(
                                    title: widget.mangaDetails.title ?? '',
                                    mangaUrl:
                                        widget.mangaDetails.mangaUrl ?? '',
                                    imageUrl:
                                        widget.mangaDetails.imageUrl ?? "",
                                    chapterUrl: mangaInfo
                                        .data.chapterList[index].chapterUrl,
                                    chapterTitle: mangaInfo
                                        .data.chapterList[index].chapterTitle,
                                    mostRecentReadDate:
                                        DateTime.now().toString());
                                List<RecentlyRead> recents =
                                    context.read<RecentsCubit>().state.recents;
                                List<ChapterRead> chaptersRead = context
                                    .read<ChaptersReadCubit>()
                                    .state
                                    .chaptersRead;
                                List<RecentlyRead> withoutCurrentRead = recents
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
                                context.read<ChaptersReadCubit>().setResults(
                                    [...withoutCurrentChapter, newChapter]);
                                await dbInstance
                                    .updateOrInsertChapterRead(newChapter);

                                await dbInstance
                                    .updateOrInsertRecentlyRead(recentlyRead);
                                Navigator.pushNamed(context, Routes.mangaReader,
                                    arguments: ChapterList(
                                        chapterUrl: mangaInfo
                                            .data.chapterList[index].chapterUrl,
                                        chapterTitle: mangaInfo.data
                                            .chapterList[index].chapterTitle,
                                        dateUploaded: mangaInfo.data
                                            .chapterList[index].dateUploaded));
                              },
                              subtitle: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  mangaInfo!
                                      .data.chapterList[index].dateUploaded,
                                  style: TextStyle(color: Color(0xffF4E8C1)),
                                ),
                              ),
                              leading: Container(
                                  padding: EdgeInsets.all(8),
                                  width: 100,
                                  child: CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                        widget.mangaDetails.imageUrl ?? ''),
                                  )),
                              title: Text(mangaInfo
                                      .data.chapterList[index].chapterTitle
                                      .replaceAll("-", " ")
                                      .split(" ")[mangaInfo.data
                                              .chapterList[index].chapterTitle
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
                    },
                    childCount: result.isLoading
                        ? 1
                        : mangaInfo != null
                            ? mangaInfo.data.chapterList.length
                            : 20,
                  ),
                ),
              ],
            );
          }),
    );
  }
}
