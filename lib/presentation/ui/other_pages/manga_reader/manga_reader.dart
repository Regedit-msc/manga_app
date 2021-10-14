import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/presentation/themes/colors.dart';

class MangaReader extends StatefulWidget {
  final ChapterList chapterList;

  const MangaReader({Key? key, required this.chapterList}) : super(key: key);

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  bool showAppBar = false;
  Future preLoadImages(List<String> listOfUrls) async {
    await Future.wait(
        listOfUrls.map((image) => cacheImage(context, image)).toList());
    isLoading.value = false;
  }

  Future cacheImage(BuildContext context, String image) =>
      precacheImage(CachedNetworkImageProvider(image), context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? PreferredSize(
              preferredSize:
                  Size(MediaQuery.of(context).size.width, kToolbarHeight),
              child: TweenAnimationBuilder(
                curve: Curves.easeInOut,
                duration: Duration(seconds: 1),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double _val, Widget? child) {
                  return Opacity(
                    opacity: _val,
                    child: child,
                  );
                },
                child: AppBar(
                  // automaticallyImplyLeading: false,
                  backgroundColor: AppColor.vulcan,
                ),
              ))
          : null,
      body: Query(
          options: QueryOptions(
            document: parseString(MANGA_READER),
            variables: {
              'chapterUrl': widget.chapterList.chapterUrl,
            },
            pollInterval: const Duration(minutes: 5),
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }

            if (result.isLoading) {
              return const Text('Loading');
            }

            final mangaToRead = result.data!["getMangaReader"];
            GetMangaReader mangaReader = GetMangaReader.fromMap(mangaToRead);
            preLoadImages(mangaReader.data.images);
            return ValueListenableBuilder(
                valueListenable: isLoading,
                builder: (context, bool val, child) {
                  return !val
                      ? SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              ...List.generate(mangaReader.data.images.length,
                                  (index) {
                                return GestureDetector(
                                  onTap: () {
                                    if (mounted) {
                                      setState(() {
                                        showAppBar = !showAppBar;
                                      });
                                      Future.delayed(Duration(seconds: 10), () {
                                        if (!mounted) return;
                                        setState(() {
                                          showAppBar = false;
                                        });
                                      });
                                    }
                                  },
                                  child: CachedNetworkImage(
                                    fadeInDuration: Duration(microseconds: 100),
                                    imageUrl: mangaReader.data.images[index],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              })
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text("Loading From cache"),
                          ],
                        );
                });
          }),
    );
  }
}
