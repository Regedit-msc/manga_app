import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/generator/custom_palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webcomic/data/common/constants/privacy.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/generator/color_generator.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_info_with_datum.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/data/models/to_download_queue.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_info/manga_info_shimmer.dart';
import 'package:webcomic/presentation/widgets/shimmer/shimmer_widgets.dart';

class MangaInfo extends StatefulWidget {
  final Datum mangaDetails;
  const MangaInfo({Key? key, required this.mangaDetails}) : super(key: key);

  @override
  _MangaInfoState createState() => _MangaInfoState();
}

class _MangaInfoState extends State<MangaInfo> with TickerProviderStateMixin {
  GeneratedImageBytesAndColor? _imageAndColor = null;
  Future<void> doSetup() async {
    ToDownloadQueue queueForThisManga = getItInstance<NavigationServiceImpl>()
        .navigationKey
        .currentContext!
        .read<ToDownloadCubit>()
        .state
        .toDownloadMangaQueue
        .firstWhere(
            (element) => element.mangaUrl == widget.mangaDetails.mangaUrl,
            orElse: () =>
                ToDownloadQueue(mangaUrl: widget.mangaDetails.mangaUrl ?? ''));
    if (!queueForThisManga.isDownloading) {
      getItInstance<NavigationServiceImpl>()
          .navigationKey
          .currentContext!
          .read<ToDownloadCubit>()
          .createQueue(
              mangaName: widget.mangaDetails.title ?? "",
              mangaUrl: widget.mangaDetails.mangaUrl ?? '');
    }

    GeneratedImageBytesAndColor _default =
        await getImageAndColors(widget.mangaDetails.imageUrl ?? '');
    if (mounted) {
      setState(() {
        _imageAndColor = _default;
      });
    }
  }

  @override
  void initState() {
    doSetup();
    super.initState();
  }

  Color getTileSelectedColor(bool shouldDrawColors, BuildContext context) {
    if (shouldDrawColors && _imageAndColor != null) {
      if (context.isLightMode()) {
        if (_imageAndColor!.palette.lightMutedColor != null) {
          return _imageAndColor!.palette.lightMutedColor!.color
              .withOpacity(0.2);
        }
      } else {
        if (_imageAndColor!.palette.darkMutedColor != null) {
          return _imageAndColor!.palette.darkMutedColor!.color.withOpacity(0.4);
        }
      }
    }
    return context.isLightMode()
        ? Colors.grey.withOpacity(0.2)
        : Colors.black54.withOpacity(0.5);
  }

  Color getTileDefaultColor(bool shouldDrawColors, BuildContext context) {
    if (shouldDrawColors && _imageAndColor != null) {
      if (context.isLightMode()) {
        if (_imageAndColor!.palette.lightMutedColor != null) {
          return _imageAndColor!.palette.lightMutedColor!.color
              .withOpacity(0.3);
        }
      } else {
        if (_imageAndColor!.palette.darkMutedColor != null) {
          return _imageAndColor!.palette.darkMutedColor!.color.withOpacity(0.3);
        }
      }
    }
    return context.isLightMode() ? Colors.white : AppColor.vulcan;
  }

  Brightness getBrightNess() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = context.read<ThemeCubit>().state.themeMode;
    if (theme == ThemeMode.dark) {
      return Brightness.light;
    } else if (theme == ThemeMode.light) {
      return Brightness.dark;
    } else {
      if (brightness == Brightness.light) {
        return Brightness.dark;
      } else {
        return Brightness.light;
      }
    }
  }

  Color getOverlayColor() {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = context.read<ThemeCubit>().state.themeMode;
    if (theme == ThemeMode.dark) {
      return Colors.transparent;
    } else if (theme == ThemeMode.light) {
      return Colors.white;
    } else {
      if (brightness == Brightness.light) {
        return Colors.white;
      } else {
        return Colors.transparent;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   systemNavigationBarColor: Colors.black,
    //   statusBarColor: Colors.transparent,
    // ));
    String computeSource() {
      final src = widget.mangaDetails.mangaSource;
      if (src != null && src.isNotEmpty) return src;
      final url = widget.mangaDetails.mangaUrl;
      if (url != null && url.isNotEmpty) {
        final parsed = Uri.tryParse(url);
        if (parsed != null && parsed.hasScheme) {
          // origin = scheme://host[:port]
          final origin =
              '${parsed.scheme}://${parsed.host}${parsed.hasPort ? ':${parsed.port}' : ''}';
          return origin;
        }
      }
      // Fallback default (same as used in genre queries)
      return 'https://www.mgeko.cc';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Query(
          options: QueryOptions(
            document: parseString(GET_MANGA_INFO),
            variables: {
              'mangaUrl': widget.mangaDetails.mangaUrl ?? '',
              "source": computeSource()
            },
            pollInterval: null,
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            GetMangaInfo? mangaInfo;
            if (result.isNotLoading && !result.hasException) {
              final resultData = result.data!["getMangaInfo"];

              mangaInfo = GetMangaInfo.fromMap(resultData);
            }

            if (result.isLoading) {
              return const MangaInfoShimmer();
            }

            if (mangaInfo != null) {
              final GetMangaInfo mi = mangaInfo;
              return RefreshIndicator(
                onRefresh: () async {
                  await refetch!();
                },
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: ScreenUtil.screenHeight / 3,
                      automaticallyImplyLeading: false,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        widget.mangaDetails.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeText.whiteBodyText2?.copyWith(
                            fontSize: Sizes.dimen_20.sp,
                            fontWeight: FontWeight.w900),
                      ),
                      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
                          statusBarIconBrightness: getBrightNess(),
                          statusBarColor: getOverlayColor()),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ScaleAnim(
                              onTap: () async {
                                final DatabaseHelper dbInstance =
                                    getItInstance<DatabaseHelper>();
                                List<Subscribe> subs =
                                    context.read<SubsCubit>().state.subs;
                                Subscribe newSub = Subscribe(
                                    imageUrl:
                                        widget.mangaDetails.imageUrl ?? '',
                                    dateSubscribed: DateTime.now().toString(),
                                    title: widget.mangaDetails.title ?? '',
                                    mangaUrl:
                                        widget.mangaDetails.mangaUrl ?? '');
                                int indexOfCurrentMangaIfSubbed =
                                    subs.indexWhere((element) =>
                                        element.mangaUrl ==
                                        widget.mangaDetails.mangaUrl);
                                if (indexOfCurrentMangaIfSubbed != -1) {
                                  getItInstance<SnackbarServiceImpl>()
                                      .showSnack(
                                    context,
                                    "${widget.mangaDetails.title} has been removed from subscriptions.",
                                  );
                                  subs.removeWhere((element) =>
                                      element.mangaUrl ==
                                      widget.mangaDetails.mangaUrl);
                                  context.read<SubsCubit>().setSubs(subs);
                                } else {
                                  getItInstance<SnackbarServiceImpl>()
                                      .showSnack(
                                    context,
                                    "${widget.mangaDetails.title} has been added to subscriptions.",
                                  );
                                  if (!context
                                      .read<SettingsCubit>()
                                      .state
                                      .settings
                                      .subscribedNotifications) {
                                    getItInstance<SnackbarServiceImpl>()
                                        .showSnack(
                                      context,
                                      "You will be not notified when ${widget.mangaDetails.title} updates. Enable subscription notifications in settings then resubscribe.",
                                    );
                                  } else {
                                    getItInstance<SnackbarServiceImpl>()
                                        .showSnack(
                                      context,
                                      "You will be  notified when ${widget.mangaDetails.title} updates. To disable subscription notifications turn it off in settings.",
                                    );
                                  }
                                  context
                                      .read<SubsCubit>()
                                      .setSubs([...subs, newSub]);
                                }
                                await getItInstance<GQLRawApiServiceImpl>()
                                    .subscribe(widget.mangaDetails.title ?? '');
                                await dbInstance
                                    .updateOrInsertSubscription(newSub);
                              },
                              child: BlocBuilder<SubsCubit, SubsState>(
                                  builder: (context, subsState) {
                                int indexOfCurrentMangaIfSubbed = subsState.subs
                                    .indexWhere((element) =>
                                        element.mangaUrl ==
                                        widget.mangaDetails.mangaUrl);
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            Sizes.dimen_10.sp),
                                        color: Colors.white),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        indexOfCurrentMangaIfSubbed != -1
                                            ? 'UNSUBSCRIBE'
                                            : 'SUBSCRIBE',
                                        style: TextStyle(
                                            fontSize: Sizes.dimen_10.sp,
                                            color: AppColor.vulcan,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            ScaleAnim(
                              onTap: () {
                                String? userDetails =
                                    getItInstance<SharedServiceImpl>()
                                        .getGoogleDetails();
                                if (userDetails != null) {
                                  Navigator.pushNamed(
                                      context, Routes.addToCollection,
                                      arguments: MangaInfoWithDatum(
                                          mangaInfo: mangaInfo,
                                          datum: widget.mangaDetails));
                                } else {
                                  showModalBottomSheet(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      context: context,
                                      backgroundColor: context.isLightMode()
                                          ? Colors.white
                                          : AppColor.vulcan,
                                      isScrollControlled: true,
                                      builder: (context) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor:
                                                      context.isLightMode()
                                                          ? Colors.white
                                                          : Colors.black,
                                                  backgroundColor:
                                                      context.isLightMode()
                                                          ? AppColor.vulcan
                                                          : Colors.white,
                                                ),
                                                onPressed: () async {
                                                  print(
                                                      "Google Sign-In temporarily disabled");
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                        "Sign Up with Google to continue",
                                                        style: TextStyle(
                                                            fontSize: Sizes
                                                                .dimen_18.sp)),
                                                    SizedBox(
                                                      width: Sizes.dimen_10.w,
                                                    ),
                                                    Container(
                                                      width: Sizes.dimen_50.w,
                                                      height: Sizes.dimen_50.h,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          image: DecorationImage(
                                                              image: CachedNetworkImageProvider(
                                                                  "https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-suite-everything-you-need-know-about-google-newest-0.png"))),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: Sizes.dimen_30),
                                              RichText(
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                      text:
                                                          "By continuing you agree to the ",
                                                      style: TextStyle(
                                                          color: context
                                                                  .isLightMode()
                                                              ? Colors.black
                                                              : Colors.white)),
                                                  TextSpan(
                                                      text:
                                                          "terms and conditions ",
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () async {
                                                              Uri url = Uri.parse(
                                                                  AppPolicies
                                                                      .TERMS_LINK);
                                                              if (await canLaunchUrl(
                                                                  url)) {
                                                                await launchUrl(
                                                                    url);
                                                              } else {
                                                                print(
                                                                    "Cannot launch");
                                                              }
                                                            },
                                                      mouseCursor:
                                                          SystemMouseCursors
                                                              .precise,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColor.violet)),
                                                  TextSpan(
                                                      text:
                                                          "and acknowledge that you have read the ",
                                                      style: TextStyle(
                                                          color: context
                                                                  .isLightMode()
                                                              ? Colors.black
                                                              : Colors.white)),
                                                  TextSpan(
                                                      text: "privacy policy.",
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () async {
                                                              Uri url = Uri.parse(
                                                                  AppPolicies
                                                                      .PRIVACY_LINK);
                                                              if (await canLaunchUrl(
                                                                  url)) {
                                                                await launchUrl(
                                                                    url);
                                                              } else {
                                                                print(
                                                                    "Cannot launch");
                                                              }
                                                            },
                                                      mouseCursor:
                                                          SystemMouseCursors
                                                              .precise,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColor.violet)),
                                                ]),
                                              )
                                            ],
                                          ),
                                        );
                                      });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: callSvg("assets/web_comic_logo.svg",
                                    width: Sizes.dimen_18.w,
                                    height: Sizes.dimen_18.h),
                              ),
                            ),
                            ScaleAnim(
                              onTap: () {
                                Navigator.pushNamed(context, Routes.summary,
                                    arguments: mangaInfo);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.info, color: Colors.white),
                              ),
                            ),
                            ScaleAnim(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, Routes.downloadView,
                                    arguments: MangaInformationForDownload(
                                        mangaDetails: widget.mangaDetails,
                                        chapterList:
                                            mangaInfo!.data.chapterList,
                                        colorPalette: _imageAndColor != null
                                            ? _imageAndColor!.palette
                                            : PaletteGenerator.fromColors([])));
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    Icon(Icons.download, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                      elevation: 0.0,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: widget.mangaDetails.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  color: Colors.black.withOpacity(0.5),
                                  colorBlendMode: BlendMode.darken,
                                ),
                              ),
                              // Optional gradient overlay for nicer look
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black54,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Content section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and author
                            Text(
                              widget.mangaDetails.title ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(mi.data.author,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.grey)),
                            const SizedBox(height: 12),
                            // Genres chips
                            if (mi.data.genres.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: mi.data.genres
                                    .map((g) => Chip(
                                          label: Text(g.genre),
                                          backgroundColor: context.isLightMode()
                                              ? Colors.grey.shade200
                                              : Colors.white10,
                                        ))
                                    .toList(),
                              ),
                            SizedBox(height: Sizes.dimen_12.h),
                            // Stats
                            Row(
                              children: [
                                _InfoStat(
                                    icon: Icons.menu_book_rounded,
                                    label: 'Chapters',
                                    value: mi.data.chapterNo),
                                const SizedBox(width: 12),
                                _InfoStat(
                                    icon: Icons.visibility_rounded,
                                    label: 'Views',
                                    value: mi.data.views),
                                const SizedBox(width: 12),
                                _InfoStat(
                                    icon: Icons.schedule_rounded,
                                    label: 'Status',
                                    value: mi.data.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, Routes.summary,
                                          arguments: mi);
                                    },
                                    icon:
                                        const Icon(Icons.info_outline_rounded),
                                    label: const Text('Summary'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, Routes.downloadView,
                                          arguments:
                                              MangaInformationForDownload(
                                            mangaDetails: widget.mangaDetails,
                                            chapterList: mi.data.chapterList,
                                            colorPalette: _imageAndColor != null
                                                ? _imageAndColor!.palette
                                                : PaletteGenerator.fromColors(
                                                    []),
                                          ));
                                    },
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text('Download'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Summary',
                                style: TextStyle(
                                    fontSize: Sizes.dimen_18.sp,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(
                              mi.data.description.trim(),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            Text('Chapters',
                                style: TextStyle(
                                    fontSize: Sizes.dimen_18.sp,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),

                    // Chapters list
                    BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settingsBloc) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: mi.data.chapterList.length,
                            (ctx, index) {
                              return BlocBuilder<ChaptersReadCubit,
                                  ChaptersReadState>(
                                builder: (context, chapterReadState) {
                                  final isRead = chapterReadState.chaptersRead
                                          .indexWhere((element) =>
                                              element.chapterUrl ==
                                              mi.data.chapterList[index]
                                                  .chapterUrl) !=
                                      -1;
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? getTileSelectedColor(
                                              settingsBloc.settings
                                                  .drawChapterColorsFromImage,
                                              context)
                                          : Colors.transparent,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          EdgeInsets.only(left: Sizes.dimen_4),
                                      isThreeLine: true,
                                      onTap: () async {
                                        final DatabaseHelper dbInstance =
                                            getItInstance<DatabaseHelper>();
                                        ChapterRead newChapter = ChapterRead(
                                            mangaUrl:
                                                widget.mangaDetails.mangaUrl ??
                                                    'none',
                                            chapterUrl: mi.data
                                                .chapterList[index].chapterUrl);
                                        RecentlyRead recentlyRead =
                                            RecentlyRead(
                                                title:
                                                    widget.mangaDetails.title ??
                                                        '',
                                                mangaUrl: widget.mangaDetails
                                                        .mangaUrl ??
                                                    '',
                                                imageUrl: widget.mangaDetails
                                                        .imageUrl ??
                                                    "",
                                                chapterUrl: mi
                                                    .data
                                                    .chapterList[index]
                                                    .chapterUrl,
                                                chapterTitle: mi
                                                    .data
                                                    .chapterList[index]
                                                    .chapterTitle,
                                                mostRecentReadDate:
                                                    DateTime.now().toString());
                                        List<RecentlyRead> recents = context
                                            .read<RecentsCubit>()
                                            .state
                                            .recents;
                                        List<ChapterRead> chaptersRead = context
                                            .read<ChaptersReadCubit>()
                                            .state
                                            .chaptersRead;
                                        List<RecentlyRead> withoutCurrentRead =
                                            recents
                                                .where((element) =>
                                                    element.mangaUrl !=
                                                    recentlyRead.mangaUrl)
                                                .toList();
                                        List<ChapterRead>
                                            withoutCurrentChapter = chaptersRead
                                                .where((element) =>
                                                    element.chapterUrl !=
                                                    newChapter.chapterUrl)
                                                .toList();

                                        context
                                            .read<RecentsCubit>()
                                            .setResults([
                                          ...withoutCurrentRead,
                                          recentlyRead
                                        ]);
                                        context
                                            .read<ChaptersReadCubit>()
                                            .setResults([
                                          ...withoutCurrentChapter,
                                          newChapter
                                        ]);
                                        await dbInstance
                                            .updateOrInsertChapterRead(
                                                newChapter);

                                        await dbInstance
                                            .updateOrInsertRecentlyRead(
                                                recentlyRead);
                                        await Navigator.pushNamed(
                                            context, Routes.mangaReader,
                                            arguments: ChapterList(
                                                mangaImage:
                                                    widget.mangaDetails.imageUrl ??
                                                        '',
                                                mangaTitle:
                                                    widget.mangaDetails.title ??
                                                        '',
                                                mangaUrl:
                                                    widget.mangaDetails.mangaUrl ??
                                                        '',
                                                chapterUrl: mi
                                                    .data
                                                    .chapterList[index]
                                                    .chapterUrl,
                                                chapterTitle: mi
                                                    .data
                                                    .chapterList[index]
                                                    .chapterTitle,
                                                dateUploaded: mi
                                                    .data
                                                    .chapterList[index]
                                                    .dateUploaded));
                                      },
                                      subtitle: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 16, 0, 0),
                                        child: Text(
                                          mi.data.chapterList[index]
                                              .dateUploaded,
                                          style: TextStyle(
                                              color: context.isLightMode()
                                                  ? AppColor.vulcan
                                                      .withOpacity(0.6)
                                                  : const Color(0xffF4E8C1)),
                                        ),
                                      ),
                                      leading: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: AspectRatio(
                                          aspectRatio: 3 / 4,
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                widget.mangaDetails.imageUrl ??
                                                    '',
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                const ShimmerBox(
                                                    height: 90, width: 70),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                    color:
                                                        Colors.grey.shade300),
                                          ),
                                        ),
                                      ),
                                      title: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          mi.data.chapterList[index].chapterTitle
                                                  .replaceAll("-", " ")
                                                  .split(" ")[mi
                                                          .data
                                                          .chapterList[index]
                                                          .chapterTitle
                                                          .split("-")
                                                          .indexWhere((element) =>
                                                              element ==
                                                              "chapter") +
                                                      1]
                                                  .replaceFirst("c", "C") +
                                              " " +
                                              mi.data.chapterList[index].chapterTitle
                                                  .replaceAll("-", " ")
                                                  .split(" ")[mi
                                                      .data
                                                      .chapterList[index]
                                                      .chapterTitle
                                                      .split("-")
                                                      .indexWhere(
                                                          (element) => element == "chapter") +
                                                  2],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // Recommendations
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        child: Text('Recommended',
                            style: TextStyle(
                                fontSize: Sizes.dimen_18.sp,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: Sizes.dimen_180 + Sizes.dimen_20,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final rec = mi.data.recommendations[index];
                            return SizedBox(
                              width: 140,
                              child: ScaleAnim(
                                onTap: () {
                                  Navigator.of(context).pushReplacementNamed(
                                      Routes.mangaInfo,
                                      arguments: newestMMdl.Datum(
                                          title: rec.title,
                                          mangaUrl: rec.mangaUrl,
                                          imageUrl: rec.mangaImage,
                                          mangaSource: mi.data.mangaSource));
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(Sizes.dimen_6),
                                      child: AspectRatio(
                                        aspectRatio: 3 / 4,
                                        child: CachedNetworkImage(
                                          imageUrl: rec.mangaImage,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              NoAnimationLoading(),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      rec.title.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: Sizes.dimen_14.sp,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: mi.data.recommendations.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            }
            return Loading();
          }),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isLight ? Colors.grey.shade200 : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
