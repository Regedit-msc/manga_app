import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/categories.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_by_genre_model.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MangaByGenreCard extends StatefulWidget {
  final String genre;
  const MangaByGenreCard({Key? key, required this.genre}) : super(key: key);

  @override
  _MangaByGenreCardState createState() => _MangaByGenreCardState();
}

class _MangaByGenreCardState extends State<MangaByGenreCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      child: Query(
        options: QueryOptions(
            document: parseString(MANGA_BY_GENRE),
            pollInterval: null,
            variables: {
              "genreUrl": "/browse-comics/?genre_included=${widget.genre}",
              "source": 'https://www.mgeko.cc'
            }),
        builder: (QueryResult result, {refetch, fetchMore}) {
          // if (result.hasException) {
          //   return Text(result.exception.toString());
          // }

          if (result.isLoading) {
            // return NoAnimationLoading();
            return const SizedBox();
          }
          final mangaInfo = result.data?["getMangaByGenre"];
          if (mangaInfo != null) {
            GetMangaByGenre newestManga = GetMangaByGenre.fromMap(mangaInfo);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ScaleAnim(
                onTap: () {
                  Navigator.pushNamed(context, Routes.categories,
                      arguments: getGenre(widget.genre));
                },
                child: Container(
                  width: Sizes.dimen_150.w,
                  height: Sizes.dimen_60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5), BlendMode.darken),
                          fit: BoxFit.cover,
                          image: CachedNetworkImageProvider(
                              newestManga.data[1].mangaImage))),
                  child: Center(
                      child: Text(
                    widget.genre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )),
                ),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}
