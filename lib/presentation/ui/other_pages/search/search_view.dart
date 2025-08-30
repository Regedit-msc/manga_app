import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
// removed: size constants/extensions not needed after UI refresh
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/manga_search_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/widgets/shimmer/shimmer_widgets.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

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
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  // Recent searches
  static const _recentKey = 'recent_searches_v1';
  List<String> recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    searchController
        .addListener(() => _hasText.value = searchController.text.isNotEmpty);
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recent = prefs.getStringList(_recentKey) ?? [];
    });
  }

  Future<void> _addRecent(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    // Move to front, unique, keep last 8
    list.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    list.insert(0, query);
    if (list.length > 8) list.removeRange(8, list.length);
    await prefs.setStringList(_recentKey, list);
    setState(() => recent = list);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    setState(() => recent = []);
  }

  onSearchChanged(String query, GraphQLClient client) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      isSearching.value = true;

      final queryOptions = QueryOptions(
          document: parseString(MANGA_SEARCH), variables: {"term": query});

      // Log the search query
      DebugLogger.logApiCall(
        operationType: 'GraphQL Query',
        operationName: 'mangaSearch - Search for: "$query"',
        variables: {"term": query},
      );

      QueryResult result = await client.query(queryOptions);

      // Log the search response
      DebugLogger.logGraphQLResponse(
          result, 'mangaSearch - Search for: "$query"');

      final resultData = result.data?["mangaSearch"];
      MangaSearch mangaSearchRes = MangaSearch.fromMap(resultData);
      context.read<MangaResultsCubit>().setResults(mangaSearchRes.data);
      isSearching.value = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    isSearching.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLConsumer(builder: (client) {
      final isLight = context.isLightMode();
      final surface = Theme.of(context).colorScheme.surface;
      final onSurface = Theme.of(context).colorScheme.onSurface;
      final fillColor = isLight ? Colors.grey.shade100 : Colors.white10;

      void triggerSearch([String? maybe]) {
        final q = (maybe ?? searchController.text).trim();
        if (q.length < 3) return;
        if (mounted) {
          setState(() => hasSearched = true);
        }
        onSearchChanged(q, client);
      }

      return SafeArea(
        child: Scaffold(
          backgroundColor: surface,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern search bar row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    // Back
                    ScaleAnim(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded,
                            color: onSurface.withOpacity(0.9)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Input
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: onSurface.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (v) {
                                  _addRecent(v);
                                  triggerSearch(v);
                                },
                                onChanged: (v) {
                                  if (v.length >= 3) triggerSearch(v);
                                },
                                cursorColor:
                                    isLight ? AppColor.vulcan : Colors.white,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search manga, authors, genres…',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Clear or loading or search button
                            ValueListenableBuilder(
                              valueListenable: isSearching,
                              builder: (_, bool searching, __) {
                                if (searching) {
                                  return const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  );
                                }
                                return ValueListenableBuilder(
                                  valueListenable: _hasText,
                                  builder: (_, bool hasText, __) {
                                    if (hasText) {
                                      return GestureDetector(
                                        onTap: () {
                                          searchController.clear();
                                          context
                                              .read<MangaResultsCubit>()
                                              .setResults([]);
                                          setState(() => hasSearched = false);
                                        },
                                        child: Icon(Icons.close_rounded,
                                            color: onSurface.withOpacity(0.7)),
                                      );
                                    }
                                    return GestureDetector(
                                      onTap: () {
                                        _addRecent(searchController.text);
                                        triggerSearch();
                                      },
                                      child: Icon(Icons.tune_rounded,
                                          color: onSurface.withOpacity(0.7)),
                                    );
                                  },
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Suggestion chips when idle
              if (!hasSearched ||
                  (hasSearched &&
                      context
                          .read<MangaResultsCubit>()
                          .state
                          .mangaSearchResults
                          .isEmpty))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recent.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent searches',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            TextButton(
                              onPressed: _clearRecent,
                              child: const Text('Clear all'),
                            )
                          ],
                        ),
                      if (recent.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final q in recent)
                              _ChipButton(
                                label: q,
                                onTap: () {
                                  searchController.text = q;
                                  _addRecent(q);
                                  triggerSearch(q);
                                },
                              )
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text('Try popular searches',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in const [
                            'Naruto',
                            'One Piece',
                            'Bleach',
                            'Attack on Titan',
                            'Romance',
                            'Comedy',
                            'Isekai',
                            'Martial Arts',
                          ])
                            _ChipButton(
                              label: q,
                              onTap: () {
                                searchController.text = q;
                                _addRecent(q);
                                triggerSearch(q);
                              },
                            )
                        ],
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: BlocBuilder<MangaResultsCubit, MangaResultsState>(
                  builder: (context, mangaResults) {
                    return ValueListenableBuilder(
                      valueListenable: isSearching,
                      builder: (context, bool searching, _) {
                        if (searching) {
                          // Shimmer grid while loading
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: 9,
                              itemBuilder: (_, __) => const ShimmerBox(
                                height: double.infinity,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          );
                        }

                        if (mangaResults.mangaSearchResults.isEmpty) {
                          if (!hasSearched) {
                            return const SizedBox.shrink();
                          }
                          // Empty state
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.search,
                                      size: 48,
                                      color: onSurface.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No results for "${'' + searchController.text}"',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try a different keyword or check the spelling.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: onSurface.withOpacity(0.7)),
                                  )
                                ],
                              ),
                            ),
                          );
                        }

                        // Results grid
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: mangaResults.mangaSearchResults.length,
                            itemBuilder: (context, index) {
                              final item =
                                  mangaResults.mangaSearchResults[index];
                              final imageUrl = (item.mangaSource ?? '') +
                                  (item.imageUrl ?? '');
                              return _MangaCard(
                                title: item.title ?? '',
                                imageUrl: imageUrl,
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.mangaInfo,
                                      arguments: Datum(
                                          mangaUrl: item.mangaUrl,
                                          mangaSource: item.mangaSource,
                                          imageUrl: item.imageUrl,
                                          title: item.title));
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade100
        : Colors.white10;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: onSurface.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;
  const _MangaCard(
      {required this.title, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                // Decode near the on-screen size to avoid huge bitmaps
                memCacheWidth: 400,
                memCacheHeight: 600,
                maxWidthDiskCache: 600,
                maxHeightDiskCache: 900,
                placeholder: (ctx, _) => const Center(
                  child: NoAnimationLoading(),
                ),
                errorWidget: (ctx, _, __) => Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            // Gradient overlay bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
