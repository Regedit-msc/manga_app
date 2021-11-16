import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:webcomic/data/common/constants/controllers.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_updates_model.dart'
    as mangaUpdateMdl;
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/cont_scale_animation.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/download_tab.dart';
import 'package:webcomic/presentation/ui/base/base_view_pages/widgets/manga_updates_tab.dart';
import 'package:webcomic/presentation/ui/blocs/manga_updates/manga_updates_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class RecentsView extends StatefulWidget {
  const RecentsView({Key? key}) : super(key: key);

  @override
  _RecentsViewState createState() => _RecentsViewState();
}

class _RecentsViewState extends State<RecentsView>
    with TickerProviderStateMixin {
  @override
  void initState() {
    recentsViewController =
        TabController(initialIndex: 0, vsync: this, length: 5);
    super.initState();
  }

  @override
  void dispose() {
    recentsViewController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My comics"),
        backgroundColor: context.isLightMode() ? Colors.white : AppColor.vulcan,
        bottom: TabBar(
          isScrollable: true,
          controller: recentsViewController,
          tabs: [
            Tab(
              child: Text(
                "RECENTS",
              ),
            ),
            Tab(
              child: Text("SUBSCRIPTIONS"),
            ),
            Tab(
              child: Text("UPDATES"),
            ),
            Tab(
              child: Text("DOWNLOADS"),
            ),
            Tab(
              child: Text("NOTIFICATIONS"),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: recentsViewController,
        children: [
          BlocBuilder<RecentsCubit, RecentsState>(
              builder: (context, recentState) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: recentState.recents.length > 0
                        ? Column(
                            children: [
                              ...List.generate(recentState.recents.length,
                                  (index) {
                                return GestureDetector(
                                  onTap: () async {
                                    final DatabaseHelper dbInstance =
                                        getItInstance<DatabaseHelper>();
                                    RecentlyRead recentlyRead = RecentlyRead(
                                        title: recentState.recents[index].title,
                                        mangaUrl:
                                            recentState.recents[index].mangaUrl,
                                        imageUrl:
                                            recentState.recents[index].imageUrl,
                                        chapterUrl: recentState
                                            .recents[index].chapterUrl,
                                        chapterTitle: recentState
                                            .recents[index].chapterTitle,
                                        mostRecentReadDate:
                                            DateTime.now().toString());
                                    List<RecentlyRead> recents = context
                                        .read<RecentsCubit>()
                                        .state
                                        .recents;
                                    List<RecentlyRead> withoutCurrentRead =
                                        recents
                                            .where((element) =>
                                                element.mangaUrl !=
                                                recentlyRead.mangaUrl)
                                            .toList();
                                    context.read<RecentsCubit>().setResults(
                                        [...withoutCurrentRead, recentlyRead]);
                                    await dbInstance.updateOrInsertRecentlyRead(
                                        recentlyRead);
                                    Navigator.pushNamed(
                                        context, Routes.mangaReader,
                                        arguments: ChapterList(
                                            mangaImage: recentState
                                                .recents[index].imageUrl,
                                            mangaTitle: recentState
                                                .recents[index].title,
                                            mangaUrl: recentState
                                                .recents[index].mangaUrl,
                                            chapterUrl: recentState
                                                .recents[index].chapterUrl,
                                            chapterTitle: recentState
                                                .recents[index].chapterTitle,
                                            dateUploaded: recentState
                                                .recents[index]
                                                .mostRecentReadDate));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.withOpacity(0.3),
                                            width: 0.1)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: Sizes.dimen_100,
                                                height: Sizes.dimen_100,
                                                child: CachedNetworkImage(
                                                  fadeInDuration:
                                                      const Duration(
                                                          microseconds: 100),
                                                  imageUrl: recentState
                                                      .recents[index].imageUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, string) {
                                                    return Container(
                                                        width: Sizes.dimen_100,
                                                        height: Sizes.dimen_100,
                                                        child:
                                                            NoAnimationLoading());
                                                  },
                                                ),
                                              ),
                                              SizedBox(
                                                width: Sizes.dimen_20,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    recentState.recents[index]
                                                                .title.length <
                                                            25
                                                        ? recentState
                                                            .recents[index]
                                                            .title
                                                        : recentState
                                                                .recents[index]
                                                                .title
                                                                .substring(
                                                                    0, 20) +
                                                            "...",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  SizedBox(
                                                    height: Sizes.dimen_10,
                                                  ),
                                                  Text(
                                                    recentState.recents[index]
                                                            .chapterTitle
                                                            .replaceAll(
                                                                "-", " ")
                                                            .split(" ")[
                                                                recentState.recents[index].chapterTitle.split("-").indexWhere((element) => element == "chapter") +
                                                                    1]
                                                            .replaceFirst(
                                                                "c", "C") +
                                                        " " +
                                                        recentState
                                                            .recents[index]
                                                            .chapterTitle
                                                            .replaceAll(
                                                                "-", " ")
                                                            .split(" ")[recentState
                                                                .recents[index]
                                                                .chapterTitle
                                                                .split("-")
                                                                .indexWhere(
                                                                    (element) =>
                                                                        element == "chapter") +
                                                            2],
                                                    style: TextStyle(
                                                        color: context
                                                                .isLightMode()
                                                            ? Colors.black54
                                                                .withOpacity(
                                                                    0.5)
                                                            : Colors.white70),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                            child: Padding(
                                          padding: EdgeInsets.only(
                                              right: Sizes.dimen_2),
                                          child: Text(
                                            timeago
                                                .format(DateTime.parse(
                                                    recentState.recents[index]
                                                        .mostRecentReadDate))
                                                .replaceAll("ago", ""),
                                            style: const TextStyle(
                                                color: AppColor.violet),
                                          ),
                                        )),
                                      ],
                                    ),
                                  ),
                                );
                              })
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    top: ScreenUtil.screenWidth / 2),
                                child: callSvg("assets/subscribed.svg",
                                    width: 70.0, height: 70.0),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("No chapter here."),
                              )
                            ],
                          ),
                  ),
                ),
              ],
            );
          }),
          BlocBuilder<SubsCubit, SubsState>(builder: (context, subsState) {
            List<mangaUpdateMdl.Datum>? mangaUpdates =
                context.read<MangaUpdatesCubit>().state.updates;
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: subsState.subs.length > 0
                          ? Column(
                              children: [
                                ...List.generate(subsState.subs.length,
                                    (index) {
                                  return GestureDetector(
                                    onTap: () async {
                                      Navigator.pushNamed(
                                          context, Routes.mangaInfo,
                                          arguments: newestMMdl.Datum(
                                              title:
                                                  subsState.subs[index].title,
                                              mangaUrl: subsState
                                                  .subs[index].mangaUrl,
                                              imageUrl: subsState
                                                  .subs[index].imageUrl));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              width: 0.1)),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                      width: Sizes.dimen_100,
                                                      height: Sizes.dimen_100,
                                                      child: CachedNetworkImage(
                                                        fadeInDuration:
                                                            const Duration(
                                                                microseconds:
                                                                    100),
                                                        imageUrl: subsState
                                                            .subs[index]
                                                            .imageUrl,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (ctx, string) {
                                                          return Container(
                                                              width: Sizes
                                                                  .dimen_100,
                                                              height: Sizes
                                                                  .dimen_100,
                                                              child:
                                                                  NoAnimationLoading());
                                                        },
                                                      ),
                                                    ),
                                                    mangaUpdates!
                                                                .take(50)
                                                                .toList()
                                                                .indexWhere((element) =>
                                                                    element
                                                                        .title
                                                                        .toLowerCase() ==
                                                                    subsState
                                                                        .subs[
                                                                            index]
                                                                        .title
                                                                        .toLowerCase()) !=
                                                            -1
                                                        ? Align(
                                                            alignment: Alignment
                                                                .topRight,
                                                            child:
                                                                ContinuousScaleAnim(
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: AppColor
                                                                        .royalBlue),
                                                                child: Padding(
                                                                  padding: EdgeInsets
                                                                      .all(Sizes
                                                                          .dimen_4
                                                                          .w),
                                                                  child: Text(
                                                                    "UP",
                                                                    style: TextStyle(
                                                                        fontSize: Sizes
                                                                            .dimen_14
                                                                            .sp,
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width: Sizes.dimen_20,
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      subsState
                                                                  .subs[index]
                                                                  .title
                                                                  .length <
                                                              25
                                                          ? subsState
                                                              .subs[index].title
                                                          : subsState
                                                                  .subs[index]
                                                                  .title
                                                                  .substring(
                                                                      0, 20) +
                                                              "...",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                              child: Padding(
                                            padding: EdgeInsets.only(
                                                right: Sizes.dimen_2),
                                            child: Text(
                                              timeago
                                                  .format(DateTime.parse(
                                                      subsState.subs[index]
                                                          .dateSubscribed))
                                                  .replaceAll("ago", ""),
                                              style: const TextStyle(
                                                  color: AppColor.violet),
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: ScreenUtil.screenWidth / 2),
                                  child: callSvg("assets/boruto.svg",
                                      width: 70.0, height: 70.0),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(Sizes.dimen_20.w),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                            "You have not subscribed to any comic. You will not get update notifications."),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
          MangaUpdatesTabView(),
          DownloadTab(),
          Container(
            child: Center(
              child: Text("WORK IN PROGRESS"),
            ),
          ),
        ],
      ),
    );
  }
}

// Padding(
// padding: EdgeInsets.only(
// top: Sizes.dimen_8.h,
// bottom: Sizes.dimen_8.h),
// child: Stack(
// children: [
// ListTile(

// trailing: Text(
// timeago.format(DateTime.parse(
// )),
// style: const TextStyle(
// color: Colors.cyan),
// ),
// leading: CircleAvatar(
// radius: Sizes.dimen_30.w,
// backgroundImage:
// CachedNetworkImageProvider(

// ),
// title:
// ),

// ],
// ),
// );
