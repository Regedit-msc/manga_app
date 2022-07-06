import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/models/google_models/user.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newsestMMdl;
import 'package:webcomic/data/services/cache/cache_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/collection_cards/collection_cards_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';

class CreateCollection extends StatefulWidget {
  bool fromAddToCollectionPage;
  CreateCollection({Key? key, this.fromAddToCollectionPage = false})
      : super(key: key);

  @override
  _CreateCollectionState createState() => _CreateCollectionState();
}

class _CreateCollectionState extends State<CreateCollection> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  ValueNotifier<Map<String, dynamic>?> collectionImage = ValueNotifier(null);

  @override
  void initState() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    collectionImage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create a collection"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text("1",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  Text(
                    "Give your collection a name. ",
                    style: TextStyle(fontSize: Sizes.dimen_16.sp),
                  ),
                ],
              ),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                                  cursorColor: !context.isLightMode()
                                      ? AppColor.vulcan
                                      : Colors.white,
                                  // controller: searchController,
                                  onChanged: (v) {
                                    if (v.length < 3) return;
                                    // onSearchChanged(v, client);
                                  },
                                  controller: _nameController,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !context.isLightMode()
                                          ? AppColor.vulcan
                                          : Colors.white),
                                  decoration: new InputDecoration.collapsed(
                                      hintText: 'Collection name',
                                      hintStyle: TextStyle(
                                          color: AppColor
                                              .bottomNavUnselectedColor)),
                                ),
                              ),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Text("2",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  Text(
                    "Add some comics. ",
                    style: TextStyle(fontSize: Sizes.dimen_16.sp),
                  ),
                ],
              ),
              BlocBuilder<CollectionCardsCubit, CollectionCardsState>(
                  builder: (context, data) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(children: [
                    ...List.generate(data.cards.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TweenAnimationBuilder(
                            duration: Duration(seconds: 1),
                            tween: Tween<double>(begin: 0.0, end: 1),
                            builder: (context, double _val, child) {
                              return Transform.translate(
                                offset: Offset(_val, 0.0),
                                child: Opacity(
                                  opacity: _val,
                                  child: child,
                                ),
                              );
                            },
                            child: collectionCard(
                                data.cards[index], context, index)),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: createCollectionCard(context),
                    ),
                  ]),
                );
              }),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.brown,
                    child: Text("3",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  Text(
                    "Describe your collection. ",
                    style: TextStyle(fontSize: Sizes.dimen_16.sp),
                  ),
                ],
              ),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                                  cursorColor: !context.isLightMode()
                                      ? AppColor.vulcan
                                      : Colors.white,
                                  controller: _descriptionController,
                                  onChanged: (v) {
                                    if (v.length < 3) return;
                                    // onSearchChanged(v, client);
                                  },
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !context.isLightMode()
                                          ? AppColor.vulcan
                                          : Colors.white),
                                  decoration: new InputDecoration.collapsed(
                                      hintText: 'Collection description',
                                      hintStyle: TextStyle(
                                          color: AppColor
                                              .bottomNavUnselectedColor)),
                                ),
                              ),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.yellow,
                    child: Text("4",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  Flexible(
                    child: Text(
                      "Choose an image for your collection from your gallery or pick a default. ",
                      style: TextStyle(fontSize: Sizes.dimen_16.sp),
                    ),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                ],
              ),
              Wrap(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: chooseImageCard(context, collectionImage),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  unsplashImages(context, collectionImage)
                ],
              ),
              SizedBox(
                height: Sizes.dimen_8.h,
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text("5",
                        style: TextStyle(
                            fontSize: Sizes.dimen_16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: Sizes.dimen_4.h,
                  ),
                  Flexible(
                    child: Text(
                      "Publish your new collection. ",
                      style: TextStyle(fontSize: Sizes.dimen_16.sp),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: context.isLightMode()
                                ? AppColor.vulcan
                                : Colors.white, // background
                            onPrimary: context.isLightMode()
                                ? Colors.white
                                : Colors.black, // foreground
                          ),
                          onPressed: () async {
                            UserFromGoogle userDetails =
                                context.read<UserFromGoogleCubit>().state.user;
                            String? firestoreUserId =
                                getItInstance<SharedServiceImpl>()
                                    .getFirestoreUserId();
                            if (_nameController.text.length < 5) {
                              getItInstance<SnackbarServiceImpl>().showSnack(
                                  context,
                                  "Your collection name is too short.");
                            } else if (_nameController.text.length > 15) {
                              getItInstance<SnackbarServiceImpl>().showSnack(
                                  context, "Your collection name is too long.");
                            } else if (_descriptionController.text.length >
                                30) {
                              getItInstance<SnackbarServiceImpl>().showSnack(
                                  context, "You are already writing a story.");
                            } else if (collectionImage.value == null) {
                              getItInstance<SnackbarServiceImpl>().showSnack(
                                  context,
                                  "Your collection must have an image. Choose a default if you don't have any. ");
                            } else if (context
                                    .read<CollectionCardsCubit>()
                                    .state
                                    .cards[0]
                                    .mangaUrl ==
                                null) {
                              getItInstance<SnackbarServiceImpl>().showSnack(
                                  context,
                                  "The first comic in your collection cannot be nothing. ");
                            } else {
                              print("In else ");
                              List<newsestMMdl.Datum> nonNullCards = context
                                  .read<CollectionCardsCubit>()
                                  .state
                                  .cards
                                  .where((element) => element.mangaUrl != null)
                                  .toList();
                              List<Map<String, dynamic>?> cards =
                                  (nonNullCards.map((e) {
                                return e.toMap();
                              }).toList());
                              if (collectionImage.value!["type"] == "local") {
                                getItInstance<SnackbarServiceImpl>().showSnack(
                                    context, "Uploading image please wait. ");
                                File imageFile =
                                    collectionImage.value!["file"] as File;
                                String fileName = basename(imageFile.path);

                                TaskSnapshot snapshot =
                                    await getItInstance<FirebaseStorage>()
                                        .ref()
                                        .child('uploads/$fileName')
                                        .putFile(imageFile);
                                if (snapshot.state == TaskState.success) {
                                  final String downloadUrl =
                                      await snapshot.ref.getDownloadURL();
                                  getItInstance<SnackbarServiceImpl>().showSnack(
                                      context,
                                      "Done with upload. Creating collection. ");
                                  Map<String, dynamic> dataToSave = {
                                    "items": cards,
                                    "collectionImageUrl": downloadUrl,
                                    "username": userDetails.name,
                                    "userId": firestoreUserId,
                                    "userProfileImage":
                                        userDetails.profilePicture,
                                    "added": DateTime.now().toString(),
                                    "description": _descriptionController.text,
                                    "name": _nameController.text,
                                    "likes": []
                                  };
                                  firestore.FirebaseFirestore
                                      firesStoreInstance = getItInstance<
                                          firestore.FirebaseFirestore>();

                                  firesStoreInstance
                                      .collection(CollectionConsts.collections)
                                      .doc(firestoreUserId)
                                      .set({
                                    "created": DateTime.now().toString()
                                  }).then((value) async {
                                    final firestore.DocumentReference
                                        documentReference =
                                        await firesStoreInstance
                                            .collection(
                                                CollectionConsts.collections)
                                            .doc(firestoreUserId)
                                            .collection(CollectionConsts
                                                .userSubCollections)
                                            .add(dataToSave);
                                    if (widget.fromAddToCollectionPage) {
                                      getItInstance<SnackbarServiceImpl>()
                                          .showSnack(context,
                                              "Successfully created collection. Tap to add your comic to ${_nameController.text} collection.",
                                              color: Colors.green);
                                      Navigator.pop(context);
                                    } else {
                                      /// take to share page with docRef Id
                                    }
                                  });
                                }
                              } else {
                                String unsplashImageUrl =
                                    collectionImage.value!["url"] as String;
                                Map<String, dynamic> dataToSave = {
                                  "items": cards,
                                  "collectionImageUrl": unsplashImageUrl,
                                  "username": userDetails.name,
                                  "userId": firestoreUserId,
                                  "userProfileImage":
                                      userDetails.profilePicture,
                                  "added": DateTime.now().toString(),
                                  "description": _descriptionController.text,
                                  "name": _nameController.text,
                                  "likes": []
                                };
                                firestore.FirebaseFirestore firesStoreInstance =
                                    getItInstance<
                                        firestore.FirebaseFirestore>();
                                firesStoreInstance
                                    .collection(CollectionConsts.collections)
                                    .doc(firestoreUserId)
                                    .set({
                                  "created": DateTime.now().toString()
                                }).then((value) async {
                                  final firestore.DocumentReference
                                      documentReference =
                                      await firesStoreInstance
                                          .collection(
                                              CollectionConsts.collections)
                                          .doc(firestoreUserId)
                                          .collection(CollectionConsts
                                              .userSubCollections)
                                          .add(dataToSave);
                                  if (widget.fromAddToCollectionPage) {
                                    getItInstance<SnackbarServiceImpl>().showSnack(
                                        context,
                                        "Successfully created collection. Tap to add your comic to ${_nameController.text} collection.",
                                        color: Colors.green);
                                    Navigator.pop(context);
                                  } else {
                                    /// take to share page with docRef Id
                                  }
                                });
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Publish",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget unsplashImages(
    BuildContext context, ValueNotifier<Map<String, dynamic>?> imageP) {
  List<String> urls =
      getItInstance<SharedServiceImpl>().getUnSplashLinks() != null
          ? getItInstance<SharedServiceImpl>().getUnSplashLinks()!.split(",")
          : [];
  urls.shuffle();
  List<String> shuffledUrls = urls.take(12).toList();
  return urls != null
      ? Wrap(
          children: [
            ...List.generate(shuffledUrls.length, (index) {
              return ScaleAnim(
                onTap: () {
                  imageP.value = {"type": "url", "url": shuffledUrls[index]};
                },
                child: Padding(
                  padding: EdgeInsets.all(Sizes.dimen_2.w),
                  child: Container(
                      height: Sizes.dimen_50.h,
                      width: Sizes.dimen_100.w,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                  shuffledUrls[index]),
                              fit: BoxFit.cover),
                          color: context.isLightMode()
                              ? AppColor.vulcan
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15.0))),
                ),
              );
            })
          ],
        )
      : Container();
}

Widget collectionCard(
    newsestMMdl.Datum cardData, BuildContext context, int index) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, Routes.addCollectionSearch,
          arguments: index);
    },
    child: Container(
      height: Sizes.dimen_60.h,
      width: Sizes.dimen_100.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: Sizes.dimen_50.h,
            width: Sizes.dimen_100.w,
            decoration: BoxDecoration(
                image: cardData.imageUrl != null
                    ? DecorationImage(
                        image:
                            CachedNetworkImageProvider(cardData.imageUrl ?? ''),
                        fit: BoxFit.cover)
                    : null,
                color: context.isLightMode() ? AppColor.vulcan : Colors.white,
                borderRadius: BorderRadius.circular(15.0)),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ScaleAnim(
              onTap: () {
                context.read<CollectionCardsCubit>().removeCardAtIndex(index);
              },
              child: Icon(
                Icons.cancel,
                color: AppColor.violet,
              ),
            ),
          ),
          cardData.imageUrl != null
              ? Container()
              : Align(
                  alignment: Alignment.center,
                  child: ScaleAnim(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.addCollectionSearch,
                          arguments: index);
                    },
                    child: Icon(
                      Icons.add_circle,
                      color: AppColor.violet,
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

Widget createCollectionCard(BuildContext context) {
  return ScaleAnim(
    onTap: () {
      int numberOfCards =
          context.read<CollectionCardsCubit>().state.cards.length;
      if (numberOfCards < 5) {
        context.read<CollectionCardsCubit>().addCard(newsestMMdl.Datum());
      } else {
        // TODO: Shout
      }
    },
    child: Padding(
      padding: EdgeInsets.only(top: Sizes.dimen_10.h, left: Sizes.dimen_2.w),
      child: Container(
        height: Sizes.dimen_40.h,
        width: Sizes.dimen_100.w,
        decoration: BoxDecoration(
            color: context.isLightMode() ? AppColor.vulcan : Colors.white,
            borderRadius: BorderRadius.circular(15.0)),
        child: Center(
            child: Icon(
          Icons.add_circle_outlined,
          size: Sizes.dimen_30.w,
          color: context.isLightMode() ? Colors.white : AppColor.vulcan,
        )),
      ),
    ),
  );
}

Widget chooseImageCard(
    BuildContext context, ValueNotifier<Map<String, dynamic>?> imageP) {
  return ScaleAnim(
    onTap: () async {
      var source = ImageSource.gallery;
      XFile? image = await getItInstance<ImagePicker>().pickImage(
          source: source,
          imageQuality: 50,
          preferredCameraDevice: CameraDevice.front);
      if (image != null) {
        imageP.value = {"type": "local", "file": File(image.path)};
      }
    },
    child: Padding(
      padding: EdgeInsets.only(top: Sizes.dimen_10.h, left: Sizes.dimen_2.w),
      child: ValueListenableBuilder(
        builder: (context, Map<String, dynamic>? value, _) {
          dynamic theVal;
          if (value != null) {
            theVal = value!["type"] == "local"
                ? value["file"] as File
                : value["url"] as String;
          }
          return value != null
              ? value!["type"] == "local"
                  ? Container(
                      height: Sizes.dimen_40.h,
                      width: Sizes.dimen_100.w,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: FileImage(theVal!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken)),
                          color: context.isLightMode()
                              ? AppColor.vulcan
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15.0)),
                      child: Center(
                          child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: Sizes.dimen_30.w,
                        color: context.isLightMode()
                            ? Colors.white
                            : AppColor.vulcan,
                      )),
                    )
                  : Container(
                      height: Sizes.dimen_40.h,
                      width: Sizes.dimen_100.w,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: CachedNetworkImageProvider(
                                theVal!,
                                cacheManager: getItInstance<CacheServiceImpl>()
                                    .getDefaultCacheOptions(),
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken)),
                          color: context.isLightMode()
                              ? AppColor.vulcan
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15.0)),
                      child: Center(
                          child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: Sizes.dimen_30.w,
                        color: context.isLightMode()
                            ? Colors.white
                            : AppColor.vulcan,
                      )),
                    )
              : Container(
                  height: Sizes.dimen_40.h,
                  width: Sizes.dimen_100.w,
                  decoration: BoxDecoration(
                      color: context.isLightMode()
                          ? AppColor.vulcan
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15.0)),
                  child: Center(
                      child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: Sizes.dimen_30.w,
                    color:
                        context.isLightMode() ? Colors.white : AppColor.vulcan,
                  )),
                );
        },
        valueListenable: imageP,
      ),
    ),
  );
}
