import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/controllers.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_updates_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/manga_updates/manga_updates_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/data/services/debug/debug_graphql_widgets.dart';

class MangaUpdatesHome extends StatefulWidget {
  const MangaUpdatesHome({Key? key}) : super(key: key);

  @override
  _MangaUpdatesHomeState createState() => _MangaUpdatesHomeState();
}

class _MangaUpdatesHomeState extends State<MangaUpdatesHome> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: GraphQLDebugHelper.loggedQuery(
        options: QueryOptions(
            document: parseString(MANGA_UPDATE),
            pollInterval: null,
            variables: {"page": 1}),
        operationName: 'getMangaPage - Manga Updates',
        builder: (QueryResult result, {refetch, fetchMore}) {
          // if (result.hasException) {
          //   return Text(result.exception.toString());
          // }

          if (result.isLoading) {
            // return NoAnimationLoading();
            return const SizedBox();
          }

          final mangaInfo = result.data?["getMangaPage"];
          if (mangaInfo != null) {
            GetMangaPage newestManga = GetMangaPage.fromMap(mangaInfo);
            context.read<MangaUpdatesCubit>().setUpdates(newestManga.data);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleAnim(
                  onTap: () {
                    baseViewPageController!.animateToPage(1,
                        duration: Duration(microseconds: 400),
                        curve: Curves.easeIn);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, 4, 4, 4),
                        child: Text(
                          "UPDATES",
                          style: TextStyle(
                              fontSize: Sizes.dimen_16.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...List.generate(newestManga.data.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ScaleAnim(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                    Routes.mangaInfo,
                                    arguments: newestMMdl.Datum(
                                        title: newestManga.data[index].title,
                                        mangaUrl:
                                            newestManga.data[index].mangaUrl,
                                        imageUrl:
                                            newestManga.data[index].imageUrl));
                              },
                              child: BlocBuilder<ThemeCubit, ThemeState>(
                                  builder: (context, themeBloc) {
                                return Container(
                                  width: Sizes.dimen_150,
                                  height: Sizes.dimen_200,
                                  decoration: BoxDecoration(
                                    // border: Border.all(
                                    //     color: Colors.grey.withOpacity(0.8)),
                                    color:
                                        themeBloc.themeMode != ThemeMode.dark &&
                                                context.isLightMode()
                                            ? Colors.white
                                            : AppColor.vulcan,
                                    borderRadius:
                                        BorderRadius.circular(Sizes.dimen_8),
                                    // boxShadow: [
                                    //   BoxShadow(
                                    //     color: Colors.black.withOpacity(0.2),
                                    //     spreadRadius: 1,
                                    //     blurRadius: 7,
                                    //     offset: Offset(0,
                                    //         2), // changes position of shadow
                                    //   )
                                    // ]
                                  ),
                                  child: Column(children: [
                                    Expanded(
                                      flex: 2,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            height: Sizes.dimen_200,
                                            child: ClipRRect(
                                              // borderRadius: BorderRadius.only(
                                              //     topRight: Radius.circular(
                                              //         Sizes.dimen_8),
                                              //     topLeft: Radius.circular(
                                              //         Sizes.dimen_8)),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Sizes.dimen_4),
                                              child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, string) {
                                                    // return NoAnimationLoading();
                                                    return const SizedBox();
                                                  },
                                                  imageUrl: newestManga
                                                      .data[index].imageUrl),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                                width: 50,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(
                                                                Sizes.dimen_8),
                                                        topRight:
                                                            Radius.circular(
                                                                Sizes.dimen_4)),
                                                    color: newestManga
                                                                .data[index]
                                                                .status
                                                                .trim()
                                                                .toLowerCase() ==
                                                            "new"
                                                        ? AppColor.violet
                                                        : newestManga
                                                                    .data[index]
                                                                    .status
                                                                    .trim()
                                                                    .toLowerCase() ==
                                                                "hot"
                                                            ? Colors.red
                                                            : Colors
                                                                .transparent),
                                                child: Center(
                                                  child: Text(
                                                    newestManga
                                                        .data[index].status,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                )),
                                          ),
                                          index == 0
                                              ? Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                      width: Sizes.dimen_100,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color:
                                                                Colors.white),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            "LATEST UPDATE",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container()
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: Sizes.dimen_8.h,
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              newestManga.data[index].title
                                                  .trim(),
                                              maxLines: 1,
                                              textAlign: TextAlign.start,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: Sizes.dimen_14.sp,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ]),
                                );
                              }),
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }
}
