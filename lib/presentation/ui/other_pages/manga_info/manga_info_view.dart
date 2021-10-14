import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/themes/text.dart';

class MangaInfo extends StatefulWidget {
  final Datum mangaDetails;
  const MangaInfo({Key? key, required this.mangaDetails}) : super(key: key);

  @override
  _MangaInfoState createState() => _MangaInfoState();
}

class _MangaInfoState extends State<MangaInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Query(
          options: QueryOptions(
            document: parseString(GET_MANGA_INFO),
            variables: {
              'mangaUrl': widget.mangaDetails.mangaUrl ?? '',
            },
            pollInterval: Duration(seconds: 10),
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
                        child: ListTile(
                          onTap: () {
                            Navigator.pushNamed(context, Routes.mangaReader,
                                arguments: ChapterList(
                                    chapterUrl: mangaInfo!
                                        .data.chapterList[index].chapterUrl,
                                    chapterTitle: mangaInfo
                                        .data.chapterList[index].chapterTitle,
                                    dateUploaded: mangaInfo
                                        .data.chapterList[index].dateUploaded));
                          },
                          leading: Container(
                              padding: EdgeInsets.all(8),
                              width: 100,
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(
                                    widget.mangaDetails.imageUrl ?? ''),
                              )),
                          title: Text(
                              mangaInfo!.data.chapterList[index].chapterTitle),
                        ),
                      );
                    },
                    childCount: result.isLoading
                        ? 1
                        : mangaInfo != null
                            ? int.parse(mangaInfo.data.chapterNo)
                            : 20,
                  ),
                ),
              ],
            );
          }),
    );
  }
}
