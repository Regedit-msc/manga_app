import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_slideshow_indicator_widget.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_clicked.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/most_viewed.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

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
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return Text('Loading');
          }

          final mangaInfo = result.data!["getNewestManga"];
          if (mangaInfo != null) {
            GetNewestManga newestManga = GetNewestManga.fromMap(mangaInfo);
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: ScreenUtil.screenWidth,
                      height: Sizes.dimen_120.h,
                      child: Stack(
                        children: [
                          PageView(
                            controller: _controller,
                            pageSnapping: true,
                            onPageChanged: (int index) {
                              context
                                  .read<MangaSlideShowCubit>()
                                  .setIndex(index + 1);
                            },
                            children: [
                              ...List.generate(newestManga.data!.length,
                                  (index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                        Routes.mangaInfo,
                                        arguments: Datum(
                                            title:
                                                newestManga.data![index].title,
                                            mangaUrl: newestManga
                                                .data![index].mangaUrl,
                                            imageUrl: newestManga
                                                .data![index].imageUrl));
                                  },
                                  child: CachedNetworkImage(
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
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                );
                              })
                            ],
                          ),
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
                          MostViewedManga(),
                          MostClickedManga(),
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
