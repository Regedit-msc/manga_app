import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/most_clicked_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MostClickedManga extends StatefulWidget {
  const MostClickedManga({Key? key}) : super(key: key);

  @override
  _MostClickedMangaState createState() => _MostClickedMangaState();
}

class _MostClickedMangaState extends State<MostClickedManga> {
  Color getColor(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return Color(0xff320E3B);
      case "completed":
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }

  IconData getIcon(String status) {
    switch (status.toLowerCase()) {
      case "ongoing":
        return Icons.access_alarm;
      case "completed":
        return Icons.clear;
      default:
        return Icons.airline_seat_individual_suite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Query(
        options: QueryOptions(
          document: parseString(MOST_CLICKED),
          pollInterval: Duration(minutes: 60),
        ),
        builder: (QueryResult result, {refetch, fetchMore}) {
          // if (result.hasException) {
          //   return Text(result.exception.toString());
          // }

          if (result.isLoading) {
            return NoAnimationLoading();
          }

          final mangaInfo = result.data!["getMostClickedManga"];
          if (mangaInfo != null) {
            GetMostClickedManga newestManga =
                GetMostClickedManga.fromMap(mangaInfo);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Most Clicked Today",
                    style: TextStyle(
                        fontSize: Sizes.dimen_16.sp,
                        fontWeight: FontWeight.bold),
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
                            child: GestureDetector(
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
                              child: Container(
                                width: Sizes.dimen_150,
                                height: Sizes.dimen_270,
                                child: Column(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: Sizes.dimen_200,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                Sizes.dimen_4),
                                            child: CachedNetworkImage(
                                                fit: BoxFit.cover,
                                                placeholder: (ctx, string) {
                                                  return NoAnimationLoading();
                                                },
                                                imageUrl: newestManga
                                                    .data[index].imageUrl),
                                          ),
                                        ),
                                        index == 0
                                            ? Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    width: Sizes.dimen_100,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                      color: Colors.white,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "MOST CLICKED",
                                                          style: TextStyle(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      10,
                                                                      10,
                                                                      10,
                                                                      0.8),
                                                              fontSize: Sizes
                                                                  .dimen_12.sp,
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
                                    child: Wrap(
                                        clipBehavior: Clip.hardEdge,
                                        children: [
                                          Text(
                                            newestManga.data[index].title
                                                .trim(),
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: Sizes.dimen_14.sp,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ]),
                                  )
                                ]),
                              ),
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
