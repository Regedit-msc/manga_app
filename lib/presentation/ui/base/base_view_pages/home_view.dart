import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_by_genre_tabular.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_genre_card.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_slideshow_indicator_widget.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_updates_home.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_clicked.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_viewed.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/quick_search_bar.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/genre_chips_row.dart';
import 'package:webcomic/presentation/widgets/shimmer/shimmer_widgets.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/widgets/design/section_header.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with AutomaticKeepAliveClientMixin {
  late PageController _controller;
  bool _ready = false;
  newestMMdl.GetNewestManga? _newest;
  final List<ImageProvider> _preloadedImages = [];
  // late Timer pager;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    _controller = PageController();
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _warmup());
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

  Future<void> _warmup() async {
    try {
      final client = GraphQLProvider.of(context).value;
      // Pre-query key sections so nested Query widgets hit cache and we can precache images.
      final newestRes = await client.query(QueryOptions(
        document: parseString(GET_NEWEST_MANGA),
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      final viewedRes = await client.query(QueryOptions(
        document: parseString(MOST_VIEWED),
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      final clickedRes = await client.query(QueryOptions(
        document: parseString(MOST_CLICKED),
        fetchPolicy: FetchPolicy.networkOnly,
      ));
      final updatesRes = await client.query(QueryOptions(
        document: parseString(MANGA_UPDATE),
        variables: {"page": 1},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      final urls = <String>{};
      final newestData = newestRes.data?['getNewestManga'];
      if (newestData != null) {
        _newest = newestMMdl.GetNewestManga.fromMap(newestData);
        urls.addAll((_newest?.data ?? [])
            .map((e) => e.imageUrl ?? '')
            .where((e) => e.isNotEmpty));
      }

      void collect(Map<String, dynamic>? root, String key, String imageKey) {
        final obj = root?[key];
        if (obj is Map && obj['data'] is List) {
          for (final m in (obj['data'] as List)) {
            final u = m[imageKey];
            if (u is String && u.isNotEmpty) urls.add(u);
          }
        }
      }

      collect(viewedRes.data, 'getMostViewedManga', 'imageUrl');
      collect(clickedRes.data, 'getMostClickedManga', 'imageUrl');
      collect(updatesRes.data, 'getMangaPage', 'imageUrl');

      // Preload a few genres used above-the-fold
      Future<void> _prefetchGenre(String genre) async {
        final res = await client.query(QueryOptions(
          document: parseString(MANGA_BY_GENRE),
          variables: {
            'source': 'https://www.mgeko.cc',
            'genreUrl': '/browse-comics/?genre_included=$genre',
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ));
        final obj = res.data?['getMangaByGenre'];
        if (obj is Map && obj['data'] is List) {
          for (final m in (obj['data'] as List).take(10)) {
            final u = m['mangaImage'];
            if (u is String && u.isNotEmpty) urls.add(u);
          }
        }
      }

      // Preload all genres used on the homepage (cards + tabular)
      const homepageGenres = [
        'Action',
        'Horror',
        'Webtoons',
        'Martial Arts',
        'Tragedy',
        'Adult',
        'Mecha',
        'Sports',
        'Isekai',
        'Love',
        'Comedy',
        'School Life',
        'Sci Fi'
      ];
      await Future.wait(homepageGenres.map(_prefetchGenre));

      // Precache all collected images
      for (final u in urls) {
        final provider = CachedNetworkImageProvider(u);
        _preloadedImages.add(provider);
        try {
          await precacheImage(provider, context);
        } catch (_) {}
      }

      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: Query(
            options: QueryOptions(
              document: parseString(GET_NEWEST_MANGA),
              pollInterval: const Duration(minutes: 60),
            ),
            builder: (QueryResult result, {refetch, fetchMore}) {
              // if (result.hasException) {
              //   // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
              //   //   getItInstance<DialogServiceImpl>().NoNetWorkDialog(refetch!());
              //   // });
              //   return NoAnimationLoading();
              // }

              if (!_ready || result.isLoading) {
                // Shimmer skeleton layout for Home page while loading
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child:
                            SizedBox(height: 48, child: ShimmerBox(height: 48)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: shimmerBanner(
                            height: Sizes.dimen_250,
                            radius: BorderRadius.circular(16)),
                      ),
                      const SizedBox(height: 12),
                      shimmerChips(),
                      const SizedBox(height: 8),
                      // Updates
                      const SectionHeader(title: 'UPDATES'),
                      shimmerHorizontalCards(
                          imageHeight: 200, cardWidth: 150, withTitle: true),
                      const SectionHeader(title: 'Most Viewed Today'),
                      shimmerHorizontalCards(
                          imageHeight: 200, cardWidth: 150, withTitle: true),
                      const SectionHeader(title: 'Most Clicked Today'),
                      shimmerHorizontalCards(
                          imageHeight: 200, cardWidth: 150, withTitle: true),
                      const SectionHeader(title: 'Genres'),
                      // A couple of tabular rows
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: shimmerRows(count: 5),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: shimmerRows(count: 5),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }

              final mangaInfo = result.data?["getNewestManga"];
              if (mangaInfo != null) {
                newestMMdl.GetNewestManga newestManga =
                    newestMMdl.GetNewestManga.fromMap(mangaInfo);
                context
                    .read<MangaSlideShowCubit>()
                    .setNoOfItems(newestManga.data!.length);
                return RefreshIndicator(
                  onRefresh: () async {
                    await refetch!();
                    await _warmup();
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: const QuickSearchBar(),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BlocBuilder<SettingsCubit,
                                            SettingsState>(
                                        builder: (context, settingsBloc) {
                                      return CarouselSlider.builder(
                                        options: CarouselOptions(
                                            aspectRatio: 16 / 9,
                                            viewportFraction: 1.0,
                                            enlargeCenterPage: false,
                                            autoPlayCurve: Curves.ease,
                                            autoPlay: true,
                                            autoPlayInterval: Duration(
                                                seconds: settingsBloc.settings
                                                    .newMangaSliderDuration),
                                            autoPlayAnimationDuration:
                                                const Duration(
                                                    milliseconds: 350),
                                            onPageChanged: (i, reason) {
                                              context
                                                  .read<MangaSlideShowCubit>()
                                                  .setIndex(i + 1);
                                            }),
                                        itemBuilder: (_, index, __) {
                                          final item = newestManga.data![index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).pushNamed(
                                                  Routes.mangaInfo,
                                                  arguments: newestMMdl.Datum(
                                                      title: item.title,
                                                      mangaUrl: item.mangaUrl,
                                                      mangaSource:
                                                          item.mangaSource,
                                                      imageUrl: item.imageUrl));
                                            },
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: item.imageUrl ?? '',
                                                  memCacheWidth: 1600,
                                                  memCacheHeight: 900,
                                                  maxWidthDiskCache: 1920,
                                                  maxHeightDiskCache: 1080,
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, _) =>
                                                      const SizedBox(),
                                                  errorWidget: (ctx, url,
                                                          err) =>
                                                      const Icon(Icons.error),
                                                ),
                                                Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.black54
                                                      ],
                                                      begin: Alignment.center,
                                                      end: Alignment
                                                          .bottomCenter,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 16,
                                                  right: 16,
                                                  bottom: 16,
                                                  child: Text(
                                                    item.title ?? '',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        itemCount: newestManga.data!.length,
                                      );
                                    }),
                                  ),
                                ),
                                const Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: SlideShowIndicator(),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: Sizes.dimen_10.h,
                              ),
                              const GenreChipsRow(genres: [
                                'Action',
                                'Horror',
                                'Webtoons',
                                'Isekai',
                                'Comedy',
                                'Sports'
                              ]),
                              const SizedBox(height: 8),
                              const MangaUpdatesHome(),
                              const MostViewedManga(),
                              const MostClickedManga(),
                              const SectionHeader(title: 'Genres'),
                              SizedBox(
                                height: Sizes.dimen_2.h,
                              ),
                              const MangaByGenreTabular(genre: "Action"),
                              const MangaByGenreTabular(genre: "Horror"),
                              const MangaByGenreTabular(genre: "Webtoons"),
                              SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        const MangaByGenreCard(genre: "Action"),
                                        const MangaByGenreCard(
                                            genre: "Martial Arts"),
                                        const MangaByGenreCard(
                                            genre: "Tragedy"),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const MangaByGenreCard(genre: "Adult"),
                                        const MangaByGenreCard(genre: "Horror"),
                                        const MangaByGenreCard(genre: "Mecha"),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const MangaByGenreCard(genre: "Sports"),
                                        const MangaByGenreCard(genre: "Isekai"),
                                        const MangaByGenreCard(genre: "Love"),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const MangaByGenreCard(genre: "Comedy"),
                                        const MangaByGenreCard(
                                            genre: "School Life"),
                                        const MangaByGenreCard(genre: "Sci Fi"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // MangaByGenreTabular(genre: "Shounen"),
                              // MangaByGenreHome(genre: "Fantasy"),
                              // MangaByGenreHome(genre: "Cooking"),
                              // MangaByGenreTabular(genre: "Manhwa"),
                              // MangaByGenreHome(genre: "Medical"),
                              // MangaByGenreHome(genre: "One Shot"),
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
