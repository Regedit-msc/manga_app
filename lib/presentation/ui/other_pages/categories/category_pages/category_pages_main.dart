import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_by_genre_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class CategoryViewMain extends StatefulWidget {
  final String category;

  const CategoryViewMain({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryViewMainState createState() => _CategoryViewMainState();
}

class _CategoryViewMainState extends State<CategoryViewMain> {
  int initialGenrePage = 2;
  ValueNotifier<bool> loading = ValueNotifier(false);

  FetchMoreOptions fetchMoreMangaByGenre() {
    return FetchMoreOptions(
      variables: {
        "genreUrl":
            "/browse/?genre=${widget.category}&filter=Random&results=${initialGenrePage}"
      },
      updateQuery: (previousResultData, fetchMoreResultData) {
        fetchMoreResultData!["getMangaByGenre"]['data'] = [
          ...previousResultData!["getMangaByGenre"]['data'],
          ...fetchMoreResultData!["getMangaByGenre"]['data']
        ];
        if (mounted) {
          setState(() {
            initialGenrePage = initialGenrePage + 1;
          });
        }
        return fetchMoreResultData;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Query(
          options: QueryOptions(
              document: parseString(MANGA_BY_GENRE),
              pollInterval: null,
              variables: {
                "genreUrl":
                    "/browse/?genre=${widget.category}&filter=Random&results=1"
              }),
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
              return LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                  onRefresh: () async {
                    await refetch!();
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.count(
                            childAspectRatio: 3/4,
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            physics: BouncingScrollPhysics(),
                            children: List.generate(
                              newestManga.data.length,
                              (index) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.mangaInfo,
                                        arguments: newestMMdl.Datum(
                                            title: newestManga
                                                .data[index].mangaTitle,
                                            mangaUrl: newestManga
                                                .data[index].mangaUrl,
                                            imageUrl: newestManga
                                                .data[index].mangaImage));
                                  },
                                  child: CardItem(
                                      imageUrl:
                                          newestManga.data[index].mangaImage,
                                      title: newestManga.data[index].mangaTitle,
                                      mangaUrl:
                                          newestManga.data[index].mangaUrl),
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ValueListenableBuilder(
                            builder: (context, bool val, child) {
                              return val
                                  ? Text("LOADING ...")
                                  : GestureDetector(
                                      onTap: () async {
                                        loading.value = true;
                                        dynamic done = await fetchMore!(
                                            fetchMoreMangaByGenre());
                                        if (done != null) {
                                          loading.value = false;
                                        }
                                      },
                                      child: Text("LOAD MORE"));
                            },
                            valueListenable: loading,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
            return Container();
          }),
    );
  }
}

class CardItem extends StatelessWidget {
  final String mangaUrl;

  final String imageUrl;

  final String title;

  const CardItem(
      {Key? key,
      required this.imageUrl,
      required this.title,
      required this.mangaUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
     // width: double.infinity,
     // height: Sizes.dimen_100.h,
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Sizes.dimen_10.sp),
              child: FittedBox(
                fit: BoxFit.fill,
                child: CachedNetworkImage(
                  width:Sizes.dimen_90.w,
                  height:Sizes.dimen_50.h,
                  fadeInDuration: const Duration(microseconds: 100),
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (ctx, string) {
                    return NoAnimationLoading();
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            height: Sizes.dimen_2.h,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
