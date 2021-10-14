import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_search_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  onSearchChanged(String query, GraphQLClient client) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      QueryResult result = await client.query(QueryOptions(
          document: parseString(MANGA_SEARCH), variables: {"term": query}));

      final resultData = result.data!["mangaSearch"];
      MangaSearch mangaSearchRes = MangaSearch.fromMap(resultData);
      context.read<MangaResultsCubit>().setResults(mangaSearchRes.data);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLConsumer(builder: (client) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  margin: const EdgeInsets.only(top: 40.0),
                  child: TextField(
                    onChanged: (v) {
                      if (v.length < 3) return;
                      onSearchChanged(v, client);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(
              height: Sizes.dimen_10.h,
            ),
            Expanded(
              flex: 6,
              child: BlocBuilder<MangaResultsCubit, MangaResultsState>(
                  builder: (context, mangaResults) {
                return Container(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: mangaResults.mangaSearchResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              onTap: () {
                                Navigator.pushNamed(context, Routes.mangaInfo,
                                    arguments: Datum(
                                        mangaUrl: mangaResults
                                            .mangaSearchResults[index].mangaUrl,
                                        imageUrl: mangaResults
                                            .mangaSearchResults[index].imageUrl,
                                        title: mangaResults
                                            .mangaSearchResults[index].title));
                              },
                              title: Text(mangaResults
                                      .mangaSearchResults[index].title ??
                                  ''),
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    mangaResults.mangaSearchResults[index]
                                            .imageUrl ??
                                        ''),
                              ),
                            ),
                          ),
                        );
                      }),
                );
              }),
            )
          ],
        ),
      );
    });
  }
}
