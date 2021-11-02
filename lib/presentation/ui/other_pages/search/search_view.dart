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
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_search_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  bool hasSearched = false;
  Timer? _debounce;
  ValueNotifier<bool> isSearching = ValueNotifier(false);

  onSearchChanged(String query, GraphQLClient client) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      isSearching.value = true;
      QueryResult result = await client.query(QueryOptions(
          document: parseString(MANGA_SEARCH), variables: {"term": query}));

      final resultData = result.data!["mangaSearch"];
      MangaSearch mangaSearchRes = MangaSearch.fromMap(resultData);
      context.read<MangaResultsCubit>().setResults(mangaSearchRes.data);
      isSearching.value = false;
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
      return SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: Container(
                            width: Sizes.dimen_200.w,
                            height: Sizes.dimen_50,
                            color: !context.isLightMode()
                                ? Colors.white
                                : AppColor.vulcan,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  autofocus: true,
                                  cursorColor: !context.isLightMode()
                                      ? AppColor.vulcan
                                      : Colors.white,
                                  controller: searchController,
                                  onChanged: (v) {
                                    if (v.length < 3) return;
                                    if (mounted) {
                                      setState(() {
                                        hasSearched = true;
                                      });
                                    }
                                    onSearchChanged(v, client);
                                  },
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !context.isLightMode()
                                          ? AppColor.vulcan
                                          : Colors.white),
                                  decoration: new InputDecoration.collapsed(
                                      hintText: 'Search Mangas',
                                      hintStyle: TextStyle(
                                          color: AppColor
                                              .bottomNavUnselectedColor)),
                                ),
                              ),
                            )),
                      ),
                    ),
                    ScaleAnim(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "CANCEL",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Sizes.dimen_18.sp),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: Sizes.dimen_10.h,
              ),
              Expanded(
                child: BlocBuilder<MangaResultsCubit, MangaResultsState>(
                    builder: (context, mangaResults) {
                  return Container(
                    child: ValueListenableBuilder(
                        valueListenable: isSearching,
                        builder: (context, bool value, _) {
                          return !value
                              ? mangaResults.mangaSearchResults.length > 0
                                  ? ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: mangaResults
                                          .mangaSearchResults.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ListTile(
                                              onTap: () {
                                                Navigator.pushNamed(
                                                    context, Routes.mangaInfo,
                                                    arguments: Datum(
                                                        mangaUrl: mangaResults
                                                            .mangaSearchResults[
                                                                index]
                                                            .mangaUrl,
                                                        imageUrl: mangaResults
                                                            .mangaSearchResults[
                                                                index]
                                                            .imageUrl,
                                                        title: mangaResults
                                                            .mangaSearchResults[
                                                                index]
                                                            .title));
                                              },
                                              title: Text(mangaResults
                                                      .mangaSearchResults[index]
                                                      .title ??
                                                  ''),
                                              leading: CircleAvatar(
                                                backgroundImage:
                                                    CachedNetworkImageProvider(
                                                        mangaResults
                                                                .mangaSearchResults[
                                                                    index]
                                                                .imageUrl ??
                                                            ''),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                  : hasSearched
                                      ? Center(
                                          child: Text(searchController.text +
                                              " not found."),
                                        )
                                      : Container()
                              : Container(
                                  width: Sizes.dimen_50.w,
                                  height: Sizes.dimen_50.h,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      backgroundColor: context.isLightMode()
                                          ? Colors.white
                                          : AppColor.vulcan,
                                      color: !context.isLightMode()
                                          ? Colors.white
                                          : AppColor.vulcan,
                                    ),
                                  ),
                                );
                        }),
                  );
                }),
              )
            ],
          ),
        ),
      );
    });
  }
}
