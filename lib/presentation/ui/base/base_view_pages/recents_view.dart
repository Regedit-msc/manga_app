import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';

class RecentsView extends StatefulWidget {
  const RecentsView({Key? key}) : super(key: key);

  @override
  _RecentsViewState createState() => _RecentsViewState();
}

class _RecentsViewState extends State<RecentsView>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(initialIndex: 0, vsync: this, length: 2);
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0.0,
        backgroundColor: AppColor.vulcan,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text("RECENTS"),
            ),
            Tab(
              child: Text("SUBSCRIPTIONS"),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocBuilder<RecentsCubit, RecentsState>(
              builder: (context, recentState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          ...List.generate(recentState.recents.length, (index) {
                            return ListTile(
                              onTap: () async {
                                final DatabaseHelper dbInstance =
                                    getItInstance<DatabaseHelper>();
                                RecentlyRead recentlyRead = RecentlyRead(
                                    title: recentState.recents[index].title,
                                    mangaUrl:
                                        recentState.recents[index].mangaUrl,
                                    imageUrl:
                                        recentState.recents[index].imageUrl,
                                    chapterUrl:
                                        recentState.recents[index].chapterUrl,
                                    chapterTitle:
                                        recentState.recents[index].chapterTitle,
                                    mostRecentReadDate:
                                        DateTime.now().toString());
                                List<RecentlyRead> recents =
                                    context.read<RecentsCubit>().state.recents;
                                List<RecentlyRead> withoutCurrentRead = recents
                                    .where((element) =>
                                        element.mangaUrl !=
                                        recentlyRead.mangaUrl)
                                    .toList();
                                context.read<RecentsCubit>().setResults(
                                    [...withoutCurrentRead, recentlyRead]);
                                await dbInstance
                                    .updateOrInsertRecentlyRead(recentlyRead);
                                Navigator.pushNamed(context, Routes.mangaReader,
                                    arguments: ChapterList(
                                        chapterUrl: recentState
                                            .recents[index].chapterUrl,
                                        chapterTitle: recentState
                                            .recents[index].chapterTitle,
                                        dateUploaded: recentState.recents[index]
                                            .mostRecentReadDate));
                              },
                              trailing: Text(
                                timeago.format(DateTime.parse(recentState
                                    .recents[index].mostRecentReadDate)),
                                style: const TextStyle(color: Colors.cyan),
                              ),
                              isThreeLine: true,
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    recentState.recents[index].imageUrl),
                              ),
                              title: Text(recentState.recents[index].title),
                              subtitle: Text(
                                recentState.recents[index].chapterTitle
                                        .replaceAll("-", " ")
                                        .split(" ")[recentState
                                                .recents[index].chapterTitle
                                                .split("-")
                                                .indexWhere((element) =>
                                                    element == "chapter") +
                                            1]
                                        .replaceFirst("c", "C") +
                                    " " +
                                    recentState.recents[index].chapterTitle
                                        .replaceAll("-", " ")
                                        .split(" ")[recentState
                                            .recents[index].chapterTitle
                                            .split("-")
                                            .indexWhere((element) =>
                                                element == "chapter") +
                                        2],
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          })
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          BlocBuilder<SubsCubit, SubsState>(builder: (context, subsState) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          ...List.generate(subsState.subs.length, (index) {
                            return ListTile(
                              onTap: () async {
                                Navigator.pushNamed(context, Routes.mangaInfo,
                                    arguments: Datum(
                                        title: subsState.subs[index].title,
                                        mangaUrl:
                                            subsState.subs[index].mangaUrl,
                                        imageUrl:
                                            subsState.subs[index].imageUrl));
                              },
                              trailing: Text(
                                timeago.format(DateTime.parse(
                                    subsState.subs[index].dateSubscribed)),
                                style: const TextStyle(color: Colors.cyan),
                              ),
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    subsState.subs[index].imageUrl),
                              ),
                              title: Text(subsState.subs[index].title),
                            );
                          })
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
