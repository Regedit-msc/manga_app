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
            pollInterval: Duration(seconds: 10),
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }

            if (result.isLoading) {
              return Text('Loading');
            }

            final mangaToRead = result.data!["getMangaReader"];
            GetMangaReader mangaReader = GetMangaReader.fromMap(mangaToRead);
            return PageView(
              scrollDirection: Axis.vertical,
              children: [
                ...List.generate(mangaReader.data.images.length, (index) {
                  return CachedNetworkImage(
                    imageUrl: mangaReader.data.images[index],
                    fit: BoxFit.cover,
                  );
                })
              ],
            );
          }),
    );
  }
}
