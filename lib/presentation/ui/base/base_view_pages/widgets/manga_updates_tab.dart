import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_updates_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

import 'ad_container.dart';

class MangaUpdatesTabView extends StatefulWidget {
  const MangaUpdatesTabView({Key? key}) : super(key: key);

  @override
  _MangaUpdatesTabViewState createState() => _MangaUpdatesTabViewState();
}

class _MangaUpdatesTabViewState extends State<MangaUpdatesTabView> {
  int initialMangaPage = 2;
  ValueNotifier<bool> loading = ValueNotifier(false);

  FetchMoreOptions fetchMoreManga() {
    return FetchMoreOptions(
      variables: {"page": initialMangaPage},
      updateQuery: (previousResultData, fetchMoreResultData) {
        fetchMoreResultData!["getMangaPage"]['data'] = [
          ...previousResultData!["getMangaPage"]['data'],
          ...fetchMoreResultData["getMangaPage"]['data']
        ];
        if (mounted) {
          setState(() {
            initialMangaPage = initialMangaPage + 1;
          });
        }
        return fetchMoreResultData;
      },
    );
  }

  @override
  void dispose() {
    loading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Query(
          options: QueryOptions(
              document: parseString(MANGA_UPDATE),
              pollInterval: null,
              variables: {"page": 1}),
          builder: (QueryResult result, {refetch, fetchMore}) {
            // if (result.hasException) {
            //   return Text(result.exception.toString());
            // }

            if (result.isLoading) {
              return NoAnimationLoading();
            }

            final mangaInfo = result.data!["getMangaPage"];
            if (mangaInfo != null) {
              GetMangaPage newestManga = GetMangaPage.fromMap(mangaInfo);
              return LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                  onRefresh: () async {
                    await refetch!();
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.count(
                            childAspectRatio: 1 / 1.8,
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            physics: BouncingScrollPhysics(),
                            children: List.generate(
                              newestManga.data.length,
                              (index) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ScaleAnim(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.mangaInfo,
                                        arguments: newestMMdl.Datum(
                                            title:
                                                newestManga.data[index].title,
                                            mangaUrl: newestManga
                                                .data[index].mangaUrl,
                                            imageUrl: newestManga
                                                .data[index].imageUrl));
                                  },
                                  child: CardItem(
                                      imageUrl:
                                          newestManga.data[index].imageUrl,
                                      title: newestManga.data[index].title,
                                      mangaUrl:
                                          newestManga.data[index].mangaUrl,
                                      status: newestManga.data[index].status),
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
                                  : ScaleAnim(
                                      onTap: () async {
                                        loading.value = true;
                                        dynamic done =
                                            await fetchMore!(fetchMoreManga());
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

  final String status;
  const CardItem(
      {Key? key,
      required this.imageUrl,
      required this.title,
      required this.mangaUrl,
      required this.status})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: double.infinity,
      // height: Sizes.dimen_100.h,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Sizes.dimen_4),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: CachedNetworkImage(
                      fadeInDuration: const Duration(microseconds: 100),
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, string) {
                        return Container(
                            width: Sizes.dimen_40,
                            height: Sizes.dimen_40,
                            child: NoAnimationLoading());
                      },
                    ),
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
                              bottomLeft: Radius.circular(Sizes.dimen_8),
                              topRight: Radius.circular(Sizes.dimen_4)),
                          color: status.trim().toLowerCase() == "new"
                              ? AppColor.violet
                              : status.trim().toLowerCase() == "hot"
                                  ? Colors.red
                                  : Colors.transparent),
                      child: Center(
                        child: Text(
                          status,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )),
                ),
              ],
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
