import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/download/download_cubit.dart';

class DownloadView extends StatefulWidget {
  final MangaInformationForDownload chapterList;
  const DownloadView({Key? key, required this.chapterList}) : super(key: key);

  @override
  _DownloadViewState createState() => _DownloadViewState();
}

class _DownloadViewState extends State<DownloadView> {
  ValueNotifier<MangaInformationForDownload?> downloadDetails =
      ValueNotifier(null);
  bool isReversed = false;
  @override
  void initState() {
    downloadDetails.value = widget.chapterList;
    super.initState();
  }

  int getIndexOfManga() {
    int index = getItInstance<NavigationServiceImpl>()
        .navigationKey
        .currentContext!
        .read<ToDownloadCubit>()
        .state
        .toDownloadMangaQueue
        .indexWhere((element) =>
            element.mangaUrl == widget.chapterList.mangaDetails.mangaUrl);
    if (index == -1) {
      getItInstance<NavigationServiceImpl>()
          .navigationKey
          .currentContext!
          .read<ToDownloadCubit>()
          .createQueue(
              mangaName: widget.chapterList.mangaDetails.title ?? "",
              mangaUrl: widget.chapterList.mangaDetails.mangaUrl ?? '');
      return getItInstance<NavigationServiceImpl>()
              .navigationKey
              .currentContext!
              .read<ToDownloadCubit>()
              .state
              .toDownloadMangaQueue
              .length -
          1;
    }
    return index;
  }

  String getTextToShowOnAppBar(ToDownloadState toDownloadState) {
    if (toDownloadState
        .toDownloadMangaQueue[getIndexOfManga()].isRangeSelectorEnabled) {
      if (toDownloadState
              .toDownloadMangaQueue[getIndexOfManga()].rangeIndexes.length <
          1) {
        return "Select initial chapter";
      } else {
        return "Select final chapter";
      }
    }
    return "Download";
  }

  @override
  void dispose() {
    downloadDetails.dispose();
    doBlocCleanUp();
    super.dispose();
  }

  void doBlocCleanUp() {
    if (getItInstance<NavigationServiceImpl>()
        .navigationKey
        .currentContext!
        .read<ToDownloadCubit>()
        .state
        .toDownloadMangaQueue[getIndexOfManga()]
        .isDownloading) return;
    getItInstance<NavigationServiceImpl>()
        .navigationKey
        .currentContext!
        .read<ToDownloadCubit>()
        .removeAllChaptersFromMangaListInQueue(
            mangaUrl: widget.chapterList.mangaDetails.mangaUrl ?? "");
  }

  List<int> totalProgress(ToDownloadState toDownload, String chapterUrl ){
    List<Map<String, dynamic>> currentlyBeingDownloaded =
        toDownload.downloads;
    print(currentlyBeingDownloaded);
    List<Map<String, dynamic>>  downloadStateForChapter = currentlyBeingDownloaded
        .where((element) => element["chapterUrl"] == chapterUrl)
        .toList();
    if(downloadStateForChapter.isNotEmpty){
      print(downloadStateForChapter.length);
      int imagesLength = downloadStateForChapter[0]["imagesLength"] ?? 0;
      int progressTotal =  downloadStateForChapter.fold(0, (t, e) => t! + e["progress"] as int) ??0;
      int status = getChapterDownloadStatus(downloadStateForChapter);
      print(progressTotal);
      return[imagesLength, progressTotal, status];
    }
    return [0,0, 0];
  }
  
  int getChapterDownloadStatus( List<Map<String, dynamic>> state){
    if(state.any((e) => e["status"] == DownloadTaskStatus.running)){
      return 1;
    }
    if(state.any((e) => e["status"] == DownloadTaskStatus.paused)){
      return 2;
    }
    if(state.every((e) => e["status"] == DownloadTaskStatus.enqueued)){
      return 4;
    }
    if(state.every((e) => e["status"] == DownloadTaskStatus.complete)){
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToDownloadCubit, ToDownloadState>(
        builder: (context, toDownload) {
      return ValueListenableBuilder(
          valueListenable: downloadDetails,
          builder: (context, MangaInformationForDownload? value, child) {
            return Scaffold(
              appBar: AppBar(
                leading: !toDownload.toDownloadMangaQueue[getIndexOfManga()]
                        .isRangeSelectorEnabled
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back))
                    : ScaleAnim(
                        onTap: () {
                          context
                              .read<ToDownloadCubit>()
                              .toggleRangeSelectorForManga(
                                  mangaUrl: value!.mangaDetails.mangaUrl ?? "",
                                  mangaName: value.mangaDetails.title ?? "");
                        },
                        child: Icon(Icons.close)),
                title: Text(getTextToShowOnAppBar(toDownload)),
                titleSpacing: 0.0,
                actions: [
                  !toDownload.toDownloadMangaQueue[getIndexOfManga()]
                          .isRangeSelectorEnabled
                      ? GestureDetector(
                          onTap: () {
                            if (toDownload
                                .toDownloadMangaQueue[getIndexOfManga()]
                                .isDownloading) return;
                            if (toDownload
                                    .toDownloadMangaQueue[getIndexOfManga()]
                                    .chaptersToDownload
                                    .length !=
                                value!.chapterList.length) {
                              context
                                  .read<ToDownloadCubit>()
                                  .addAllChaptersToMangaListInQueue(
                                      chapters: value.chapterList,
                                      mangaName: value.mangaDetails.title ?? "",
                                      mangaUrl:
                                          value.mangaDetails.mangaUrl ?? '',
                                      imageUrl:
                                          value.mangaDetails.imageUrl ?? '');
                            } else {
                              context
                                  .read<ToDownloadCubit>()
                                  .removeAllChaptersFromMangaListInQueue(
                                      mangaUrl:
                                          value.mangaDetails.mangaUrl ?? '');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(toDownload
                                        .toDownloadMangaQueue[getIndexOfManga()]
                                        .chaptersToDownload
                                        .length ==
                                    value!.chapterList.length
                                ? Icons.cancel
                                : Icons.add),
                          ))
                      : Container(),
                  !toDownload.toDownloadMangaQueue[getIndexOfManga()]
                          .isRangeSelectorEnabled
                      ? GestureDetector(
                          onTap: () {
                            List<ChapterList> newChapterList =
                                value!.chapterList.reversed.toList();
                            downloadDetails.value = MangaInformationForDownload(
                                chapterList: newChapterList,
                                mangaDetails: widget.chapterList.mangaDetails,
                                colorPalette: widget.chapterList.colorPalette);
                            isReversed = !isReversed;
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.wifi_protected_setup),
                          ))
                      : Container(),
                  GestureDetector(
                      onTap: () {
                        context
                            .read<ToDownloadCubit>()
                            .toggleRangeSelectorForManga(
                                mangaUrl: value!.mangaDetails.mangaUrl ?? '',
                                mangaName: value.mangaDetails.title ?? '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.check_circle,
                          color: toDownload
                                  .toDownloadMangaQueue[getIndexOfManga()]
                                  .isRangeSelectorEnabled
                              ? AppColor.violet
                              : null,
                        ),
                      ))
                ],
              ),
              body: ValueListenableBuilder(
                  valueListenable: downloadDetails,
                  builder:
                      (context, MangaInformationForDownload? value, child) {
                    return value != null
                        ? Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child:!toDownload.toDownloadMangaQueue[getIndexOfManga()].isDownloading?


                                  Column(
                                    children: [
                                      ...List.generate(value.chapterList.length,
                                          (index) {
                                        return Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  width: 0.1)),
                                          child: CheckboxListTile(
                                            title: Text(value.chapterList[index]
                                                    .chapterTitle
                                                    .replaceAll("-", " ")
                                                    .split(" ")[value
                                                            .chapterList[index]
                                                            .chapterTitle
                                                            .split("-")
                                                            .indexWhere(
                                                                (element) =>
                                                                    element ==
                                                                    "chapter") +
                                                        1]
                                                    .replaceFirst("c", "C") +
                                                " " +
                                                value.chapterList[index]
                                                    .chapterTitle
                                                    .replaceAll("-", " ")
                                                    .split(" ")[value.chapterList[index].chapterTitle.split("-").indexWhere((element) => element == "chapter") + 2]),
                                            subtitle: Text(
                                              value.chapterList[index]
                                                  .dateUploaded,
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            secondary: Container(
                                              width: 100,
                                              height: 100,
                                              child: CachedNetworkImage(
                                                imageUrl: value.mangaDetails
                                                        .imageUrl ??
                                                    '',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            value: toDownload
                                                        .toDownloadMangaQueue[
                                                            getIndexOfManga()]
                                                        .chaptersToDownload
                                                        .indexWhere((element) =>
                                                            element
                                                                .chapterUrl ==
                                                            value
                                                                .chapterList[
                                                                    index]
                                                                .chapterUrl) ==
                                                    -1
                                                ? false
                                                : true,
                                            tileColor: toDownload
                                                        .toDownloadMangaQueue[
                                                            getIndexOfManga()]
                                                        .rangeIndexes
                                                        .indexWhere((element) =>
                                                            element == index) ==
                                                    -1
                                                ? null
                                                : value!.colorPalette != null
                                                    ? context.isLightMode()
                                                        ? value!
                                                                    .colorPalette!
                                                                    .lightMutedColor!
                                                                    .color !=
                                                                null
                                                            ? value!
                                                                .colorPalette!
                                                                .lightMutedColor!
                                                                .color
                                                            : AppColor.violet
                                                        : value!.colorPalette!
                                                                    .darkMutedColor !=
                                                                null
                                                            ? value!
                                                                .colorPalette!
                                                                .darkMutedColor!
                                                                .color
                                                            : AppColor.violet
                                                    : AppColor.violet,
                                            activeColor: value!.colorPalette !=
                                                    null
                                                ? context.isLightMode()
                                                    ? value!
                                                                .colorPalette!
                                                                .lightMutedColor!
                                                                .color !=
                                                            null
                                                        ? value!
                                                            .colorPalette!
                                                            .lightMutedColor!
                                                            .color
                                                        : null
                                                    : value!.colorPalette!
                                                                .darkMutedColor !=
                                                            null
                                                        ? value!
                                                            .colorPalette!
                                                            .darkMutedColor!
                                                            .color
                                                        : null
                                                : null,
                                            onChanged: (v) {
                                              final chapter = ToDownloadChapter(
                                                  value.mangaDetails.imageUrl ??
                                                      '',
                                                  value.chapterList[index]
                                                      .chapterTitle,
                                                  value.chapterList[index]
                                                      .chapterUrl,
                                                  value.mangaDetails.title ??
                                                      '',
                                                  value.mangaDetails.mangaUrl ??
                                                      '');
                                              if (!toDownload
                                                  .toDownloadMangaQueue[
                                                      getIndexOfManga()]
                                                  .isRangeSelectorEnabled) {
                                                if (toDownload
                                                        .toDownloadMangaQueue[
                                                            getIndexOfManga()]
                                                        .chaptersToDownload
                                                        .indexWhere((element) =>
                                                            element
                                                                .chapterUrl ==
                                                            value
                                                                .chapterList[
                                                                    index]
                                                                .chapterUrl) ==
                                                    -1) {
                                                  context
                                                      .read<ToDownloadCubit>()
                                                      .addChapterToMangaListInQueue(
                                                          chapter: chapter,
                                                          mangaName: value
                                                                  .mangaDetails
                                                                  .title ??
                                                              "",
                                                          mangaUrl: value
                                                                  .mangaDetails
                                                                  .mangaUrl ??
                                                              "");
                                                } else {
                                                  context
                                                      .read<ToDownloadCubit>()
                                                      .removeChapterFromMangaListInQueue(
                                                          chapter: chapter,
                                                          mangaName: value
                                                                  .mangaDetails
                                                                  .title ??
                                                              "",
                                                          mangaUrl: value
                                                                  .mangaDetails
                                                                  .mangaUrl ??
                                                              "");
                                                }
                                              } else {
                                                if (toDownload
                                                        .toDownloadMangaQueue[
                                                            getIndexOfManga()]
                                                        .rangeIndexes
                                                        .length <
                                                    1) {
                                                  context
                                                      .read<ToDownloadCubit>()
                                                      .addRangeIndexForManga(
                                                          index: index,
                                                          mangaUrl: value
                                                                  .mangaDetails
                                                                  .mangaUrl ??
                                                              "",
                                                          mangaName: value
                                                                  .mangaDetails
                                                                  .title ??
                                                              "");
                                                } else {
                                                  context
                                                      .read<ToDownloadCubit>()
                                                      .addRangeIndexForManga(
                                                          index: index,
                                                          mangaUrl: value
                                                                  .mangaDetails
                                                                  .mangaUrl ??
                                                              "",
                                                          mangaName: value
                                                                  .mangaDetails
                                                                  .title ??
                                                              "");
                                                  context
                                                      .read<ToDownloadCubit>()
                                                      .rangeSelectorForManga(
                                                          chapterList:
                                                              value.chapterList,
                                                          mangaName: value
                                                                  .mangaDetails
                                                                  .title ??
                                                              '',
                                                          mangaUrl: value
                                                                  .mangaDetails
                                                                  .mangaUrl ??
                                                              '',
                                                          imageUrl: value
                                                                  .mangaDetails
                                                                  .imageUrl ??
                                                              '');
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      })
                                    ],
                                  )
                                      : Column(
                                    children: [
                                      ...List.generate(toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload.length, (index){
                                        return Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  width: 0.1)),
                                          child: ListTile(
                                            title: Text(toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterName
                                                .replaceAll("-", " ")
                                                .split(" ")[toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterName
                                                .split("-")
                                                .indexWhere(
                                                    (element) =>
                                                element ==
                                                    "chapter") +
                                                1]
                                                .replaceFirst("c", "C") +
                                                " " +
                                                toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterName
                                                    .replaceAll("-", " ")
                                                    .split(" ")[toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterName.split("-").indexWhere((element) => element == "chapter") + 2]),

                                            leading: Container(
                                              width: 100,
                                              height: 100,
                                              child: CachedNetworkImage(
                                                imageUrl: value.mangaDetails
                                                    .imageUrl ??
                                                    '',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            trailing: Container(
                                              width: Sizes.dimen_50,
                                              height: Sizes.dimen_50,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  PauseOrResume(progress:totalProgress(toDownload,toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterUrl ), toDownload: toDownload,chapterUrl: toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterUrl),
                                                 SizedBox(width: Sizes.dimen_4,),
                                                  BuildProgressIndicator(progress:totalProgress(toDownload,toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterUrl ), toDownload: toDownload,chapterUrl: toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload[index].chapterUrl),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: Sizes.dimen_100,
                                child: Center(
                                  child: ScaleAnim(
                                    onTap: () {
                                      if (toDownload
                                          .toDownloadMangaQueue[
                                              getIndexOfManga()]
                                          .chaptersToDownload
                                          .isEmpty) {
                                        getItInstance<ToastServiceImpl>()
                                            .showToast("No chapters selected.",
                                                Toast.LENGTH_SHORT);
                                      } else if(toDownload
                                          .toDownloadMangaQueue[
                                      getIndexOfManga()].isDownloading){
                                        getItInstance<ToastServiceImpl>()
                                            .showToast("Some chapters are still downloading.",
                                            Toast.LENGTH_SHORT);
                                      }

                                      else {
                                       context.read<ToDownloadCubit>().startDownload(mangaName: widget.chapterList.mangaDetails.title?? '',imageUrl: widget.chapterList.mangaDetails.imageUrl?? '',mangaUrl: widget.chapterList.mangaDetails.mangaUrl?? '');
                                      }
                                    },
                                    child: Container(
                                      width: Sizes.dimen_300.w,
                                      height: Sizes.dimen_50,
                                      decoration: BoxDecoration(
                                          color: context.isLightMode()
                                              ? AppColor.vulcan
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              Sizes.dimen_6)),
                                      child: Center(
                                        child: Text(
                                          toDownload
                                                  .toDownloadMangaQueue[
                                                      getIndexOfManga()]
                                                  .chaptersToDownload
                                                  .isEmpty
                                              ? "NO CHAPTER"
                                              : toDownload
                            .toDownloadMangaQueue[
                        getIndexOfManga()].isDownloading? "DOWNLOADING (${toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload.length})" :"DOWNLOAD (${toDownload.toDownloadMangaQueue[getIndexOfManga()].chaptersToDownload.length})",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: context.isLightMode()
                                                  ? value!
                                                              .colorPalette!
                                                              .lightMutedColor!
                                                              .color !=
                                                          null
                                                      ? value!
                                                          .colorPalette!
                                                          .lightMutedColor!
                                                          .color
                                                      : AppColor.violet
                                                  : value!.colorPalette!
                                                              .darkMutedColor !=
                                                          null
                                                      ? value!.colorPalette!
                                                          .darkMutedColor!.color
                                                      : AppColor.violet,
                                              fontSize: Sizes.dimen_18.sp),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : Container();
                  }),
            );
          });
    });
  }
}



class PauseOrResume extends StatefulWidget {
  final ToDownloadState toDownload;

  final String chapterUrl;
  final List<int> progress;
  const PauseOrResume({Key? key,required this.toDownload, required this.chapterUrl, required this.progress}) : super(key: key);

  @override
  _PauseOrResumeState createState() => _PauseOrResumeState();
}

class _PauseOrResumeState extends State<PauseOrResume> {
  bool isRunning = true;
  @override
  void initState() {
    super.initState();
  }
  void setPauseOrResume(){
    List<Map<String, dynamic>> currentlyBeingDownloaded =
        widget.toDownload.downloads;
    List<Map<String, dynamic>>  downloadStateForChapter = currentlyBeingDownloaded
        .where((element) => element["chapterUrl"] ==  widget.chapterUrl)
        .toList();
    if(downloadStateForChapter.any((element) => element["status"]== DownloadTaskStatus.running )){
      setState(() {
        isRunning= true;
      });
    } else {
      setState(() {
        isRunning= false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if((  widget.progress[1]/( widget.progress[0]*100) ) != 1.0){
      return  isRunning? GestureDetector(
          onTap: () async {
          await   context.read<ToDownloadCubit>().pauseChapterDownload(chapterUrl: widget.chapterUrl);
            setState(() {
              isRunning= false;
            });
          },
          child: Icon(Icons.pause, size: Sizes.dimen_20)) : GestureDetector(
          onTap: () async {
           await  context.read<ToDownloadCubit>().resumeChapterDownload(chapterUrl: widget.chapterUrl);
            setState(() {
              isRunning= true;
            });
          },
          child: Icon(Icons.refresh, size: Sizes.dimen_20));

    }
    return Container();
  }
}





class BuildProgressIndicator extends StatefulWidget {
  final ToDownloadState toDownload;

  final String chapterUrl;
  final List<int> progress;
  const BuildProgressIndicator({Key? key,required ToDownloadState this.toDownload ,  required String this.chapterUrl, this.progress = const[0,0]}) : super(key: key);

  @override
  _BuildProgressIndicatorState createState() => _BuildProgressIndicatorState();
}

class _BuildProgressIndicatorState extends State<BuildProgressIndicator> {
  IconData getIconToShowForStatus(int status){
    switch(status){
      case 1:
        return Icons.download;
      case 2:
        return Icons.pause;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.watch_later;
        default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.dimen_20,
      height: Sizes.dimen_20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(getIconToShowForStatus(widget.progress[2]),
            size: Sizes.dimen_20,
          ),
          CircularProgressIndicator(
            backgroundColor: Colors.transparent,
            value: !(  widget.progress[1]/( widget.progress[0]*100) ).isNaN && (  widget.progress[1]/( widget.progress[0]*100) ) != double.infinity && (  widget.progress[1]/( widget.progress[0]*100) ) > 0? (  widget.progress[1]/( widget.progress[0]*100) ): 0,
            valueColor: new AlwaysStoppedAnimation<Color>(AppColor.violet),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}



