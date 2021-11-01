import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/generator/color_generator.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';

class NewlyAddedCollections extends StatefulWidget {
  const NewlyAddedCollections({Key? key}) : super(key: key);

  @override
  _NewlyAddedCollectionsState createState() => _NewlyAddedCollectionsState();
}

class _NewlyAddedCollectionsState extends State<NewlyAddedCollections> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenUtil.screenWidth,
      height: Sizes.dimen_100.h,
      child: StreamBuilder<firestore.QuerySnapshot>(
          stream: getItInstance<firestore.FirebaseFirestore>()
              .collection(CollectionConsts.collections)
              .orderBy("created", descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<firestore.QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...List.generate(snapshot.data!.docs.length, (index) {
                      print(snapshot.data!.docs.length);
                      return FutureBuilder(
                          future: getItInstance<firestore.FirebaseFirestore>()
                              .collection(CollectionConsts.collections)
                              .doc(snapshot.data!.docs[index].id)
                              .collection(CollectionConsts.userSubCollections)
                              .orderBy("added", descending: true)
                              .get(),
                          builder: (context,
                              AsyncSnapshot<firestore.QuerySnapshot> v) {
                            if (v.hasData) {
                              v.data!.docs.sort((dynamic a, dynamic b) => a
                                  .data()!["added"]
                                  .compareTo(b.data()!["added"]));
                              dynamic collectionData = v.data!.docs != null &&
                                      v.data!.docs.length > 0
                                  ? v.data!.docs.first
                                  : null;
                              return ScaleAnim(
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, Routes.subCollection,
                                      arguments: SubcollectionFields(
                                          collectionId:
                                              snapshot.data!.docs[index].id,
                                          subcollectionId:
                                              v.data!.docs.first.id));
                                },
                                child: collectionData != null
                                    ? Container(
                                        width: ScreenUtil.screenWidth,
                                        height: Sizes.dimen_100.h,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0)),
                                        child: FutureBuilder(
                                            future: getPalette(collectionData![
                                                "collectionImageUrl"]),
                                            builder: (context, dynamic snap) {
                                              if (snap.hasData) {
                                                final PaletteGenerator pallete =
                                                    snap.data
                                                        as PaletteGenerator;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: context
                                                              .isLightMode()
                                                          ? pallete.dominantColor !=
                                                                  null
                                                              ? pallete
                                                                  .dominantColor!
                                                                  .color
                                                              : AppColor.vulcan
                                                          : pallete.vibrantColor !=
                                                                  null
                                                              ? pallete
                                                                  .vibrantColor!
                                                                  .color
                                                              : AppColor.vulcan,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2.0),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(5.0),
                                                              child: Hero(
                                                                tag: collectionData![
                                                                    "collectionImageUrl"],
                                                                child:
                                                                    Container(
                                                                  width: double
                                                                      .infinity,
                                                                  decoration: BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              5.0),
                                                                      image: DecorationImage(
                                                                          fit: BoxFit
                                                                              .cover,
                                                                          image:
                                                                              CachedNetworkImageProvider(collectionData!["collectionImageUrl"]))),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      "${collectionData!["name"].toString().toUpperCase()}",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize: Sizes
                                                                              .dimen_16
                                                                              .sp),
                                                                    ),
                                                                    SizedBox(
                                                                      width: Sizes
                                                                          .dimen_2
                                                                          .h,
                                                                    ),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        "${collectionData!["description"]}",
                                                                        style: TextStyle(
                                                                            color: pallete.lightMutedColor != null
                                                                                ? pallete.lightMutedColor!.color
                                                                                : Colors.white,
                                                                            fontSize: Sizes.dimen_14.sp),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                CircleAvatar(
                                                                  backgroundColor: context
                                                                          .isLightMode()
                                                                      ? pallete.dominantColor !=
                                                                              null
                                                                          ? pallete
                                                                              .dominantColor!
                                                                              .color
                                                                          : AppColor
                                                                              .vulcan
                                                                      : pallete.vibrantColor !=
                                                                              null
                                                                          ? pallete
                                                                              .vibrantColor!
                                                                              .color
                                                                          : AppColor
                                                                              .vulcan,
                                                                  backgroundImage:
                                                                      CachedNetworkImageProvider(
                                                                          collectionData![
                                                                              "userProfileImage"]),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                child: Center(
                                                    child: Text("Loading")),
                                              );
                                            }))
                                    : Container(),
                              );
                            }
                            return Container();
                          });
                    })
                  ],
                ),
              );
            }
            return Loading();
          }),
    );
  }
}
