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
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_slideshow_indicator_widget.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Query(
        options: QueryOptions(
          document: parseString(GET_NEWEST_MANGA),
          pollInterval: Duration(minutes: 10),
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
            return Container(
              width: ScreenUtil.screenWidth,
              height: Sizes.dimen_120.h,
              child: Stack(
                children: [
                  PageView(
                    controller: _controller,
                    pageSnapping: true,
                    onPageChanged: (int index) {
                      context.read<MangaSlideShowCubit>().setIndex(index + 1);
                    },
                    children: [
                      ...List.generate(newestManga.data!.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(Routes.mangaInfo,
                                arguments: Datum(
                                    title: newestManga.data![index].title,
                                    mangaUrl: newestManga.data![index].mangaUrl,
                                    imageUrl:
                                        newestManga.data![index].imageUrl));
                          },
                          child: CachedNetworkImage(
                            imageUrl: newestManga.data![index].imageUrl ?? '',
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                            placeholder: (context, url) =>
                                Center(child: CircularProgressIndicator()),
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
                        Navigator.pushNamed(context, Routes.mangaSearch);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: Sizes.dimen_40,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
          return Container();
        },
      )),
    );
  }
}
