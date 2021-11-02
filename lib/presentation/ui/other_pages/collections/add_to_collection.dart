import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/models/manga_info_with_datum.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newsestMMdl;
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class AddToCollection extends StatefulWidget {
  final MangaInfoWithDatum? mangaInfo;
  const AddToCollection({Key? key, required this.mangaInfo}) : super(key: key);

  @override
  _AddToCollectionState createState() => _AddToCollectionState();
}

class _AddToCollectionState extends State<AddToCollection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose a collection"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScaleAnim(
                onTap: () {
                  Navigator.pushNamed(context, Routes.createCollection,
                      arguments: true);
                },
                child: Icon(Icons.add)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              StreamBuilder(
                  stream: getItInstance<firestore.FirebaseFirestore>()
                      .collection(CollectionConsts.collections)
                      .doc(getItInstance<SharedServiceImpl>()
                          .getFirestoreUserId())
                      .collection(CollectionConsts.userSubCollections)
                      .snapshots(),
                  builder: (context,
                      AsyncSnapshot<firestore.QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          child: Text("An error occurred."),
                        ),
                      );
                    }
                    if (snapshot.hasData) {
                      return Column(children: [
                        ...List.generate(snapshot.data!.docs.length, (index) {
                          return ScaleAnim(
                            onTap: () {
                              if (snapshot.data!.docs[index]["items"].length <
                                      5 &&
                                  snapshot.data!.docs[index]["items"]
                                          .indexWhere((e) =>
                                              e["mangaUrl"] ==
                                              widget
                                                  .mangaInfo!.datum.mangaUrl) ==
                                      -1) {
                                getItInstance<firestore.FirebaseFirestore>()
                                    .collection(CollectionConsts.collections)
                                    .doc(getItInstance<SharedServiceImpl>()
                                        .getFirestoreUserId())
                                    .collection(
                                        CollectionConsts.userSubCollections)
                                    .doc(snapshot.data!.docs[index].id)
                                    .update({
                                  "items": firestore.FieldValue.arrayUnion([
                                    newsestMMdl.Datum(
                                      imageUrl:
                                          widget.mangaInfo!.datum.imageUrl,
                                      mangaUrl:
                                          widget.mangaInfo!.datum.mangaUrl,
                                      title: widget.mangaInfo!.datum.title,
                                    ).toMap()
                                  ])
                                }).then((_) {
                                  getItInstance<SnackbarServiceImpl>().showSnack(
                                      context,
                                      "${widget.mangaInfo!.datum.title} has been added to ${snapshot.data!.docs[index]["name"]} collection.",
                                      color: Colors.red);
                                  Navigator.pop(context);
                                });
                              } else if (snapshot
                                      .data!.docs[index]["items"].length >=
                                  5) {
                                getItInstance<SnackbarServiceImpl>().showSnack(
                                    context,
                                    "${snapshot.data!.docs[index]["name"]} collection is  full.",
                                    color: Colors.red);
                              } else if (snapshot.data!.docs[index]["items"]
                                      .indexWhere((e) =>
                                          e["mangaUrl"] ==
                                          widget.mangaInfo!.datum.mangaUrl) !=
                                  -1) {
                                getItInstance<SnackbarServiceImpl>().showSnack(
                                    context,
                                    "${widget.mangaInfo!.datum.title} is already in ${snapshot.data!.docs[index]["name"]} collection.",
                                    color: Colors.red);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: Sizes.dimen_300.w,
                                      height: Sizes.dimen_100.h,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(
                                                  Colors.black.withOpacity(0.5),
                                                  BlendMode.darken),
                                              image: CachedNetworkImageProvider(
                                                  snapshot.data!.docs[index]
                                                      ["collectionImageUrl"])),
                                          color: Colors.white),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "${snapshot.data!.docs[index]["name"]}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Row(
                                                children: [
                                                  ...List.generate(
                                                      snapshot
                                                          .data!
                                                          .docs[index]["items"]
                                                          .length, (indx) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      child: Container(
                                                        width: Sizes.dimen_50.w,
                                                        height:
                                                            Sizes.dimen_40.h,
                                                        decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            image: DecorationImage(
                                                                fit: BoxFit
                                                                    .cover,
                                                                image: CachedNetworkImageProvider(snapshot
                                                                            .data!
                                                                            .docs[index]
                                                                        [
                                                                        "items"][indx]
                                                                    [
                                                                    "imageUrl"]))),
                                                      ),
                                                    );
                                                  })
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                      ]);
                    }
                    return NoAnimationLoading();
                  })
            ],
          ),
        ),
      ),
    );
  }
}
