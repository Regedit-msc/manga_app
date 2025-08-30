import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_by_genre_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/services/cache/cache_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MangaByGenreHome extends StatefulWidget {
  final String genre;
  const MangaByGenreHome({Key? key, required this.genre}) : super(key: key);

  @override
  _MangaByGenreHomeState createState() => _MangaByGenreHomeState();
}

class _MangaByGenreHomeState extends State<MangaByGenreHome> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Query(
        options: QueryOptions(
            document: parseString(MANGA_BY_GENRE),
            pollInterval: null,
            variables: {"genreUrl": "/browse/?genre=${widget.genre}"}),
        builder: (QueryResult result, {refetch, fetchMore}) {
          // if (result.hasException) {
          //   return Text(result.exception.toString());
          // }

          if (result.isLoading) {
            return NoAnimationLoading();
          }

          final mangaInfo = result.data?["getMangaByGenre"];
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
                                        title:
                                            newestManga.data[index].mangaTitle,
                                        mangaUrl:
                                            newestManga.data[index].mangaUrl,
                                        imageUrl: newestManga
                                            .data[index].mangaImage));
                              },
                              child: Container(
                                width: Sizes.dimen_150,
                                height: Sizes.dimen_200,
                                child: Column(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                        width: double.infinity,
                                        height: Sizes.dimen_200,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              Sizes.dimen_4),
                                          child: CachedNetworkImage(
                                              cacheManager: getItInstance<
                                                      CacheServiceImpl>()
                                                  .getDefaultCacheOptions(),
                                              key: UniqueKey(),
                                              fit: BoxFit.cover,
                                              placeholder: (ctx, string) {
                                                return NoAnimationLoading();
                                              },
                                              imageUrl: newestManga
                                                  .data[index].mangaImage),
                                        )),
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
                                            newestManga.data[index].mangaTitle
                                                .trim(),
                                            maxLines: 1,
                                            textAlign: TextAlign.start,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: Sizes.dimen_14.sp,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          Text(newestManga.data[index].stats
                                                      .trim()
                                                      .length >
                                                  0
                                              ? newestManga.data[index].stats
                                                  .replaceAll("-eng-li", '')
                                                  .replaceAll("Latest",
                                                      "Latest Chapter")
                                              : '')
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
