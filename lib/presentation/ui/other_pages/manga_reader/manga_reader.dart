import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';

class MangaReader extends StatefulWidget {
  final ChapterList chapterList;

  const MangaReader({Key? key, required this.chapterList}) : super(key: key);

  @override
  _MangaReaderState createState() => _MangaReaderState();
}

class _MangaReaderState extends State<MangaReader> {
  ValueNotifier<bool> isLoading = ValueNotifier(true);

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
      appBar: AppBar(),
      body: Query(
          options: QueryOptions(
            document: parseString(MANGA_READER),
            variables: {
              'chapterUrl': widget.chapterList.chapterUrl,
            },
            pollInterval: const Duration(seconds: 10),
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
                      ? PageView(
                          scrollDirection: Axis.vertical,
                          children: [
                            ...List.generate(mangaReader.data.images.length,
                                (index) {
                              return CachedNetworkImage(
                                fadeInDuration: Duration(microseconds: 100),
                                imageUrl: mangaReader.data.images[index],
                                fit: BoxFit.cover,
                              );
                            })
                          ],
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
