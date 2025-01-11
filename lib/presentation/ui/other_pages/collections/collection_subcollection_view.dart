import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newsestMMdl;
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class CollectionSubcollectionView extends StatefulWidget {
  final String collectionId;

  final String subCollectionId;

  const CollectionSubcollectionView(
      {Key? key, required this.collectionId, required this.subCollectionId})
      : super(key: key);

  @override
  _CollectionSubcollectionViewState createState() =>
      _CollectionSubcollectionViewState();
}

class _CollectionSubcollectionViewState
    extends State<CollectionSubcollectionView> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<Object>(
            stream: getItInstance<firestore.FirebaseFirestore>()
                .collection(CollectionConsts.collections)
                .doc(widget.collectionId)
                .collection(CollectionConsts.userSubCollections)
                .doc(widget.subCollectionId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data as dynamic;
                return NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: ScreenUtil.screenHeight / 3,
                        automaticallyImplyLeading: false,
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                                child: Text(
                              innerBoxIsScrolled ? data["name"] : "",
                              style: ThemeText.whiteBodyText2?.copyWith(
                                  fontSize: Sizes.dimen_20.sp,
                                  fontWeight: FontWeight.w900),
                            )),
                          ],
                        ),
                        actions: [
                          ScaleAnim(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                  context, Routes.collectionMain,
                                  arguments: widget.collectionId);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2.0),
                              child: CircleAvatar(
                                backgroundColor: context.isLightMode()
                                    ? AppColor.vulcan
                                    : Colors.white,
                                backgroundImage: CachedNetworkImageProvider(
                                  data["userProfileImage"],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ScaleAnim(
                              onTap: () async {
                                String url =
                                    "https://compound.com/collection/subcollection?collectionId=${widget.collectionId}&subcollectionId=${widget.subCollectionId}";
                                // String dynamicLink = await getItInstance<
                                //         DynamicLinkServiceImpl>()
                                //     .createLink(url,
                                //         isSubCollection: true,
                                //         title: data["name"],
                                //         desc: data["description"]);
                                //
                                // Share.share(dynamicLink);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                        elevation: 0.0,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        flexibleSpace:
                            LayoutBuilder(builder: (context, constraints) {
                          return Hero(
                            tag: data["collectionImageUrl"],
                            child: Stack(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            Colors.black.withOpacity(0.5),
                                            BlendMode.darken),
                                        child: CachedNetworkImage(
                                            imageUrl:
                                                data["collectionImageUrl"] ??
                                                    '',
                                            fit: BoxFit.cover,
                                            colorBlendMode: BlendMode.darken),
                                      ),
                                    ),
                                  ],
                                ),
                                constraints.biggest.height >=
                                        ScreenUtil.screenHeight / 3 -
                                            kToolbarHeight
                                    ? Positioned(
                                        top: Sizes.dimen_32.h,
                                        left: Sizes.dimen_14.w,
                                        child: Container(
                                          width: ScreenUtil.screenWidth / 2,
                                          child: Wrap(
                                            children: [
                                              Text(
                                                data["name"] ?? "",
                                                style: ThemeText.whiteBodyText2
                                                    ?.copyWith(
                                                        fontSize:
                                                            Sizes.dimen_20.sp,
                                                        fontWeight:
                                                            FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Container(),
                                constraints.biggest.height >=
                                        ScreenUtil.screenHeight / 3 -
                                            kToolbarHeight
                                    ? Positioned(
                                        top: Sizes.dimen_70.h,
                                        left: Sizes.dimen_14.w,
                                        child: Container(
                                          width: ScreenUtil.screenWidth - 10,
                                          child: Wrap(
                                            clipBehavior: Clip.hardEdge,
                                            children: [
                                              Text(
                                                data["description"]
                                                            .trim()
                                                            .length >
                                                        300
                                                    ? data["description"]
                                                            .trim()
                                                            .substring(0, 100) +
                                                        "..."
                                                    : data["description"]
                                                        .trim(),
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ))
                                    : Container(),
                              ],
                            ),
                          );
                        }),
                      ),
                    ];
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Comics in this collection",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Wrap(
                          spacing: 5.0,
                          children: [
                            ...List.generate(data["items"].length, (index) {
                              return ScaleAnim(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                      Routes.mangaInfo,
                                      arguments: newsestMMdl.Datum(
                                          title: data["items"][index]["title"],
                                          mangaUrl: data["items"][index]
                                              ["mangaUrl"],
                                          imageUrl: data["items"][index]
                                              ["imageUrl"]));
                                },
                                child: Container(
                                  width: Sizes.dimen_120.w,
                                  height: Sizes.dimen_70.h,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                          data["items"][index]
                                                              ["imageUrl"]),
                                                  fit: BoxFit.cover)),
                                        ),
                                      ),
                                      Expanded(
                                          flex: 1,
                                          child: Text(
                                            data["items"][index]["title"],
                                            overflow: TextOverflow.ellipsis,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            })
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }
              return NoAnimationLoading();
            }),
      ),
    );
  }
}
