import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_by_genre_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;

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
            pollInterval: Duration(minutes: 60),
            variables: {"genreUrl": "/browse/?genre=${widget.genre}"}),
        builder: (QueryResult result, {refetch, fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return Text('Loading');
          }

          final mangaInfo = result.data!["getMangaByGenre"];
          if (mangaInfo != null) {
            GetMangaByGenre newestManga = GetMangaByGenre.fromMap(mangaInfo);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    widget.genre,
                    style: TextStyle(
                        color: Colors.white,
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
                                        title:
                                            newestManga.data[index].mangaTitle,
                                        mangaUrl:
                                            newestManga.data[index].mangaUrl,
                                        imageUrl: newestManga
                                            .data[index].mangaImage));
                              },
                              child: Container(
                                width: Sizes.dimen_150.w,
                                height: Sizes.dimen_120.h,
                                child: Column(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: Sizes.dimen_120.h,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                Sizes.dimen_8),
                                            child: CachedNetworkImage(
                                                fit: BoxFit.cover,
                                                imageUrl: newestManga
                                                    .data[index].mangaImage),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(
                                                      Sizes.dimen_10),
                                                  topRight: Radius.circular(
                                                      Sizes.dimen_10)),
                                              color: Colors.transparent,
                                            ),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.analytics_outlined,
                                                  color: Colors.white,
                                                )),
                                          ),
                                        ),
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
                                            newestManga.data[index].mangaTitle,
                                            overflow: TextOverflow.ellipsis,
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
