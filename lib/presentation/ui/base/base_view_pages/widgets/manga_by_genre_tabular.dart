import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_by_genre_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MangaByGenreTabular extends StatefulWidget {
  final String genre;
  const MangaByGenreTabular({Key? key, required this.genre}) : super(key: key);

  @override
  _MangaByGenreTabularState createState() => _MangaByGenreTabularState();
}

class _MangaByGenreTabularState extends State<MangaByGenreTabular> {
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0, viewportFraction: 0.8);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Query(
        options: QueryOptions(
            document: parseString(MANGA_BY_GENRE),
            pollInterval: null,
            variables: {"genreUrl": "/browse/?genre=${widget.genre}"}),
        builder: (QueryResult result, {refetch, fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return NoAnimationLoading();
          }

          final mangaInfo = result.data!["getMangaByGenre"];
          if (mangaInfo != null) {
            GetMangaByGenre newestManga = GetMangaByGenre.fromMap(mangaInfo);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleAnim(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.categories,
                        arguments: getGenre(widget.genre));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          widget.genre,
                          style: TextStyle(
                              fontSize: Sizes.dimen_16.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: Sizes.dimen_16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Container(
                  width: ScreenUtil.screenWidth,
                  height: Sizes.dimen_400,
                  child: PageView.builder(
                      padEnds: false,
                      scrollDirection: Axis.horizontal,
                      pageSnapping: true,
                      controller: _pageController,
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    ...List.generate(
                                        newestManga.data
                                            .take(5)
                                            .toList()
                                            .length, (idx) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ScaleAnim(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                Routes.mangaInfo,
                                                arguments: newestMMdl.Datum(
                                                    title: newestManga.data
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaTitle,
                                                    mangaUrl: newestManga.data
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaUrl,
                                                    imageUrl: newestManga.data
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaImage));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Text(
                                                  "${idx + 1}",
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_16.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Sizes.dimen_4),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 1.0),
                                                  child: Container(
                                                    width: Sizes.dimen_70.w,
                                                    height: Sizes.dimen_50,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl: newestManga.data
                                                          .take(5)
                                                          .toList()[idx]
                                                          .mangaImage,
                                                      placeholder:
                                                          (ctx, string) {
                                                        return NoAnimationLoading();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          newestManga.data
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .length >
                                                                  20
                                                              ? newestManga.data
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  "..."
                                                              : newestManga.data
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .mangaTitle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Text(newestManga.data
                                                                .skip(5)
                                                                .take(5)
                                                                .toList()[idx]
                                                                .author
                                                                .split(':')[1]
                                                                .length >
                                                            20
                                                        ? newestManga.data
                                                                .skip(5)
                                                                .take(5)
                                                                .toList()[idx]
                                                                .author
                                                                .split(':')[1]
                                                                .substring(
                                                                    0, 20) +
                                                            "..."
                                                        : newestManga.data
                                                            .skip(5)
                                                            .take(5)
                                                            .toList()[idx]
                                                            .author
                                                            .split(':')[1],
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    ...List.generate(
                                        newestManga.data
                                            .skip(5)
                                            .take(5)
                                            .toList()
                                            .length, (idx) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ScaleAnim(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                Routes.mangaInfo,
                                                arguments: newestMMdl.Datum(
                                                    title: newestManga.data
                                                        .skip(5)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaTitle,
                                                    mangaUrl: newestManga.data
                                                        .skip(5)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaUrl,
                                                    imageUrl: newestManga.data
                                                        .skip(5)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaImage));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Text(
                                                  "${idx + 1}",
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_16.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Sizes.dimen_4),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 1.0),
                                                  child: Container(
                                                    width: Sizes.dimen_70.w,
                                                    height: Sizes.dimen_50,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl: newestManga.data
                                                          .skip(5)
                                                          .take(5)
                                                          .toList()[idx]
                                                          .mangaImage,
                                                      placeholder:
                                                          (ctx, string) {
                                                        return NoAnimationLoading();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          newestManga.data
                                                                      .skip(5)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .length >
                                                                  20
                                                              ? newestManga.data
                                                                      .skip(5)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  "..."
                                                              : newestManga.data
                                                                  .skip(5)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .mangaTitle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      newestManga.data
                                                                  .skip(5)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .length >
                                                              20
                                                          ? newestManga.data
                                                                  .skip(5)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .substring(
                                                                      0, 20) +
                                                              "..."
                                                          : newestManga.data
                                                              .skip(5)
                                                              .take(5)
                                                              .toList()[idx]
                                                              .author
                                                              .split(':')[1],
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        if (index == 2) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    ...List.generate(
                                        newestManga.data
                                            .skip(10)
                                            .take(5)
                                            .toList()
                                            .length, (idx) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ScaleAnim(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                Routes.mangaInfo,
                                                arguments: newestMMdl.Datum(
                                                    title: newestManga.data
                                                        .skip(10)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaTitle,
                                                    mangaUrl: newestManga.data
                                                        .skip(10)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaUrl,
                                                    imageUrl: newestManga.data
                                                        .skip(10)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaImage));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Text(
                                                  "${idx + 1}",
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_16.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Sizes.dimen_4),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 1.0),
                                                  child: Container(
                                                    width: Sizes.dimen_70.w,
                                                    height: Sizes.dimen_50,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl: newestManga.data
                                                          .skip(10)
                                                          .take(5)
                                                          .toList()[idx]
                                                          .mangaImage,
                                                      placeholder:
                                                          (ctx, string) {
                                                        return NoAnimationLoading();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          newestManga.data
                                                                      .skip(10)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .length >
                                                                  20
                                                              ? newestManga.data
                                                                      .skip(10)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  "..."
                                                              : newestManga.data
                                                                  .skip(10)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .mangaTitle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      newestManga.data
                                                                  .skip(10)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .length >
                                                              20
                                                          ? newestManga.data
                                                                  .skip(10)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .substring(
                                                                      0, 20) +
                                                              "..."
                                                          : newestManga.data
                                                              .skip(10)
                                                              .take(5)
                                                              .toList()[idx]
                                                              .author
                                                              .split(':')[1],
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        if (index == 3) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    ...List.generate(
                                        newestManga.data
                                            .skip(15)
                                            .take(5)
                                            .toList()
                                            .length, (idx) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ScaleAnim(
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                                Routes.mangaInfo,
                                                arguments: newestMMdl.Datum(
                                                    title: newestManga.data
                                                        .skip(15)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaTitle,
                                                    mangaUrl: newestManga.data
                                                        .skip(15)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaUrl,
                                                    imageUrl: newestManga.data
                                                        .skip(15)
                                                        .take(5)
                                                        .toList()[idx]
                                                        .mangaImage));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(5.0),
                                                child: Text(
                                                  "${idx + 1}",
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_16.sp,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Sizes.dimen_4),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 1.0),
                                                  child: Container(
                                                    width: Sizes.dimen_70.w,
                                                    height: Sizes.dimen_50,
                                                    child: CachedNetworkImage(
                                                      fit: BoxFit.cover,
                                                      imageUrl: newestManga.data
                                                          .skip(15)
                                                          .take(5)
                                                          .toList()[idx]
                                                          .mangaImage,
                                                      placeholder:
                                                          (ctx, string) {
                                                        return NoAnimationLoading();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Text(
                                                          newestManga.data
                                                                      .skip(15)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .length >
                                                                  20
                                                              ? newestManga.data
                                                                      .skip(15)
                                                                      .take(5)
                                                                      .toList()[
                                                                          idx]
                                                                      .mangaTitle
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  "..."
                                                              : newestManga.data
                                                                  .skip(15)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .mangaTitle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                    Text(
                                                      newestManga.data
                                                                  .skip(15)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .length >
                                                              20
                                                          ? newestManga.data
                                                                  .skip(15)
                                                                  .take(5)
                                                                  .toList()[idx]
                                                                  .author
                                                                  .split(':')[1]
                                                                  .substring(
                                                                      0, 20) +
                                                              "..."
                                                          : newestManga.data
                                                              .skip(15)
                                                              .take(5)
                                                              .toList()[idx]
                                                              .author
                                                              .split(':')[1],
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    )
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                          child: Text("hello"),
                        );
                      }),
                )
              ],
            );
          }
          return Container();
        },
      ),
    );
  }
}
