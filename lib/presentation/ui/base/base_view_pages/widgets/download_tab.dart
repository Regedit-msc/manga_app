import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class DownloadTab extends StatefulWidget {
  const DownloadTab({Key? key}) : super(key: key);

  @override
  _DownloadTabState createState() => _DownloadTabState();
}

class _DownloadTabState extends State<DownloadTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DownloadedCubit, DownloadedState>(
          builder: (context, downloadState) {
        final newList = List.from(downloadState.downloadedManga);
        newList.sort((a, b) {
          return b.dateDownloaded.compareTo(a.dateDownloaded);
        });
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              ...List.generate(newList.length, (index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.downloadedChaptersView,
                        arguments: newList[index]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.3), width: 0.1)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: Sizes.dimen_100,
                                height: Sizes.dimen_100,
                                child: CachedNetworkImage(
                                  fadeInDuration:
                                      const Duration(microseconds: 100),
                                  imageUrl: newList[index].imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, string) {
                                    return Container(
                                        width: Sizes.dimen_100,
                                        height: Sizes.dimen_100,
                                        child: NoAnimationLoading());
                                  },
                                ),
                              ),
                              SizedBox(
                                width: Sizes.dimen_20,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    newList[index].mangaName.length < 25
                                        ? newList[index].mangaName
                                        : newList[index]
                                                .mangaName
                                                .substring(0, 20) +
                                            "...",
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: Sizes.dimen_10,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(right: Sizes.dimen_2),
                          child: Text(
                            timeago
                                .format(DateTime.parse(
                                    newList[index].dateDownloaded))
                                .replaceAll("ago", ""),
                            style: const TextStyle(color: AppColor.violet),
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              })
            ],
          ),
        );
      }),
    );
  }
}
