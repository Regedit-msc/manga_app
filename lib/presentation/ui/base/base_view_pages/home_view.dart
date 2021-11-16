import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/services/cache/cache_service.dart';
import 'package:webcomic/data/services/dialog/dialogs.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_by_genre_home_widget.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_by_genre_tabular.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_genre_card.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_slideshow_indicator_widget.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_updates_home.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_clicked.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_viewed.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin {
  late PageController _controller;
  // late Timer pager;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    // pager.cancel();
    super.dispose();
  }

  // void startPaging() {
  //   pager = Timer.periodic(Duration(seconds: 1), (timer) {
  //     _controller.nextPage(duration: Duration(seconds: 1), curve: Curves.ease);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
          body: Query(
        options: QueryOptions(
          document: parseString(GET_NEWEST_MANGA),
          pollInterval: Duration(minutes: 60),
        ),
        builder: (QueryResult result, {refetch, fetchMore}) {
          if (result.hasException) {
            WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
              getItInstance<DialogServiceImpl>().NoNetWorkDialog(refetch!());
            });
            return NoAnimationLoading();
          }

          if (result.isLoading) {
            return NoAnimationLoading();
          }

          final mangaInfo = result.data!["getNewestManga"];
          if (mangaInfo != null) {
            newestMMdl.GetNewestManga newestManga =
                newestMMdl.GetNewestManga.fromMap(mangaInfo);
            context
                .read<MangaSlideShowCubit>()
                .setNoOfItems(newestManga.data!.length);
            return RefreshIndicator(
              onRefresh: () async {
                await refetch!();
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: ScreenUtil.screenWidth,
                      height: Sizes.dimen_250,
                      child: Stack(
                        children: [
                          BlocBuilder<SettingsCubit, SettingsState>(
                              builder: (context, settingsBloc) {
                            return CarouselSlider.builder(
                              options: CarouselOptions(
                                  height: Sizes.dimen_250,
                                  viewportFraction: 1.0,
                                  enlargeCenterPage: true,
                                  autoPlayCurve: Curves.ease,
                                  autoPlay: true,
                                  autoPlayInterval: Duration(
                                      seconds: settingsBloc
                                          .settings.newMangaSliderDuration),
                                  autoPlayAnimationDuration:
                                      Duration(milliseconds: 200),
                                  onPageChanged: (i, reason) {
                                    context
                                        .read<MangaSlideShowCubit>()
                                        .setIndex(i + 1);
                                  }),
                              itemBuilder: (_, index, __) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.mangaInfo,
                                        arguments: newestMMdl.Datum(
                                            title:
                                                newestManga.data![index].title,
                                            mangaUrl: newestManga
                                                .data![index].mangaUrl,
                                            imageUrl: newestManga
                                                .data![index].imageUrl));
                                  },
                                  child: CachedNetworkImage(
                                    cacheManager:
                                        getItInstance<CacheServiceImpl>()
                                            .getDefaultCacheOptions(),
                                    key: UniqueKey(),
                                    imageUrl:
                                        newestManga.data![index].imageUrl ?? '',
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    placeholder: (ctx, string) {
                                      return NoAnimationLoading();
                                    },
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                );
                              },
                              itemCount: newestManga.data!.length,
                            );
                          }),
                          const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SlideShowIndicator(),
                              )),
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, Routes.mangaSearch);
                              },
                              child: Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: callSvg("assets/search.svg",
                                      color: Colors.white,
                                      width: Sizes.dimen_32.sp)),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: Sizes.dimen_10.h,
                          ),
                          MangaUpdatesHome(),
                          MostViewedManga(),
                          MostClickedManga(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Genres",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Sizes.dimen_18.sp),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Sizes.dimen_2.h,
                          ),
                          MangaByGenreTabular(genre: "All"),
                          SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    MangaByGenreCard(genre: "Action"),
                                    MangaByGenreCard(genre: "Martial Arts"),
                                    MangaByGenreCard(genre: "Tragedy"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    MangaByGenreCard(genre: "Adult"),
                                    MangaByGenreCard(genre: "Horror"),
                                    MangaByGenreCard(genre: "Mecha"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    MangaByGenreCard(genre: "Sports"),
                                    MangaByGenreCard(genre: "Isekai"),
                                    MangaByGenreCard(genre: "Romance"),
                                  ],
                                ),
                                Column(
                                  children: [
                                    MangaByGenreCard(genre: "Comedy"),
                                    MangaByGenreCard(genre: "School Life"),
                                    MangaByGenreCard(genre: "Sci Fi"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          MangaByGenreTabular(genre: "Shounen"),
                          MangaByGenreHome(genre: "Fantasy"),
                          MangaByGenreHome(genre: "Cooking"),
                          MangaByGenreTabular(genre: "Manhwa"),
                          MangaByGenreHome(genre: "Medical"),
                          MangaByGenreHome(genre: "One Shot"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
          return Container();
        },
      )),
    );
  }
}
