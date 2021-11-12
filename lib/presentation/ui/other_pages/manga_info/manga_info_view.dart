import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/data/common/constants/privacy.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/generator/color_generator.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/google_models/user.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';
import 'package:webcomic/data/models/manga_info_model.dart';
import 'package:webcomic/data/models/manga_info_with_datum.dart';
import 'package:webcomic/data/models/newest_manga_model.dart' as newestMMdl;
import 'package:webcomic/data/models/newest_manga_model.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/settings/settings_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';

class MangaInfo extends StatefulWidget {
  final Datum mangaDetails;
  const MangaInfo({Key? key, required this.mangaDetails}) : super(key: key);

  @override
  _MangaInfoState createState() => _MangaInfoState();
}

class _MangaInfoState extends State<MangaInfo> with TickerProviderStateMixin {
  GeneratedImageBytesAndColor? _imageAndColor = null;
  Future<void> doSetup() async {
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Query(
          options: QueryOptions(
            document: parseString(GET_MANGA_INFO),
            variables: {
              'mangaUrl': widget.mangaDetails.mangaUrl ?? '',
            },
            pollInterval: null,
          ),
          builder: (QueryResult result, {refetch, fetchMore}) {
            GetMangaInfo? mangaInfo;

            if (result.isNotLoading && !result.hasException) {
              final resultData = result.data!["getMangaInfo"];
              print(" result data $resultData");
              mangaInfo = GetMangaInfo.fromMap(resultData);
            }

            if (result.isLoading) {
              return NoAnimationLoading();
            }

            if (mangaInfo != null) {
              return RefreshIndicator(
                onRefresh: () async {
                  await refetch!();
                },
                child: DefaultTabController(
                  initialIndex: 1,
                  length: 3,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverAppBar(
                          expandedHeight: ScreenUtil.screenHeight / 3,
                          automaticallyImplyLeading: false,
                          leading: GestureDetector(
                            onTap: () {
                              // Future.delayed(Duration(milliseconds: 100), (){
                              //   if (context.isLightMode()) {
                              //     print("Ran reset");
                              //     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
                              //       statusBarIconBrightness: Brightness.dark,
                              //       statusBarColor: Colors.white,
                              //     ));
                              //   }
                              // });
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
                                innerBoxIsScrolled
                                    ? widget.mangaDetails.title!
                                    : "",
                                style: ThemeText.whiteBodyText2?.copyWith(
                                    fontSize: Sizes.dimen_20.sp,
                                    fontWeight: FontWeight.w900),
                              )),
                            ],
                          ),
                          systemOverlayStyle: SystemUiOverlayStyle.light
                              .copyWith(
                                  statusBarIconBrightness: getBrightNess(),
                                  statusBarColor: getOverlayColor()),
                          bottom: TabBar(
                            indicatorColor: AppColor.royalBlue,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            unselectedLabelStyle:
                                TextStyle(fontWeight: FontWeight.bold),
                            labelColor: Colors.white,
                            tabs: [
                              Tab(
                                child: Text(
                                  "ABOUT",
                                  style: TextStyle(
                                      // fontWeight: FontWeight.bold,
                                      fontSize: Sizes.dimen_12.sp),
                                ),
                              ),
                              Tab(
                                child: Text(
                                  "CHAPTERS",
                                  style: TextStyle(
                                      // fontWeight: FontWeight.bold,
                                      fontSize: Sizes.dimen_12.sp),
                                ),
                              ),
                              Tab(
                                child: Text(
                                  "RECOMMENDED",
                                  style: TextStyle(
                                      // fontWeight: FontWeight.bold,
                                      fontSize: Sizes.dimen_12.sp),
                                ),
                              ),
                            ],
                          ),
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
                                        dateSubscribed:
                                            DateTime.now().toString(),
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
                                        .subscribe(
                                            widget.mangaDetails.title ?? '');
                                    await dbInstance
                                        .updateOrInsertSubscription(newSub);
                                  },
                                  child: BlocBuilder<SubsCubit, SubsState>(
                                      builder: (context, subsState) {
                                    int indexOfCurrentMangaIfSubbed =
                                        subsState.subs.indexWhere((element) =>
                                            element.mangaUrl ==
                                            widget.mangaDetails.mangaUrl);
                                    return Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: indexOfCurrentMangaIfSubbed != -1
                                          ? Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Sizes.dimen_10.sp),
                                                  color: Colors.white),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'UNSUBSCRIBE',
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_10.sp,
                                                      color: AppColor.vulcan,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          Sizes.dimen_10.sp),
                                                  color: Colors.white),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'SUBSCRIBE',
                                                  style: TextStyle(
                                                      fontSize:
                                                          Sizes.dimen_10.sp,
                                                      color: AppColor.vulcan,
                                                      fontWeight:
                                                          FontWeight.bold),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: context
                                                              .isLightMode()
                                                          ? AppColor.vulcan
                                                          : Colors
                                                              .white, // background
                                                      onPrimary: context
                                                              .isLightMode()
                                                          ? Colors.white
                                                          : Colors
                                                              .black, // foreground
                                                    ),
                                                    onPressed: () async {
                                                      GoogleSignInAccount?
                                                          googleSignInAccount =
                                                          await getItInstance<
                                                                  GoogleSignIn>()
                                                              .signIn();
                                                      GoogleSignInAuthentication
                                                          googleSignInAuthentication =
                                                          await googleSignInAccount!
                                                              .authentication;
                                                      AuthCredential
                                                          credential =
                                                          GoogleAuthProvider
                                                              .credential(
                                                        accessToken:
                                                            googleSignInAuthentication
                                                                .accessToken,
                                                        idToken:
                                                            googleSignInAuthentication
                                                                .idToken,
                                                      );
                                                      UserCredential
                                                          authResult =
                                                          await getItInstance<
                                                                  FirebaseAuth>()
                                                              .signInWithCredential(
                                                                  credential);
                                                      Map<String, dynamic>
                                                          userData = {
                                                        "name": authResult
                                                            .user!.displayName,
                                                        "email": authResult
                                                            .user!.email,
                                                        "profilePicture":
                                                            authResult
                                                                .user!.photoURL,
                                                        "pro": "false"
                                                      };
                                                      await getItInstance<
                                                              SharedServiceImpl>()
                                                          .saveUserDetails(
                                                              jsonEncode(
                                                                  userData));
                                                      getItInstance<
                                                              SnackbarServiceImpl>()
                                                          .showSnack(context,
                                                              "Sign up successful. A new collection tab has been unlocked. Check it out!");
                                                      Navigator.pop(context);
                                                      print(authResult
                                                          .toString());
                                                      context
                                                          .read<
                                                              ShowCollectionCubit>()
                                                          .setShowCollection(
                                                              true);
                                                      context
                                                          .read<
                                                              UserFromGoogleCubit>()
                                                          .setUser(UserFromGoogle
                                                              .fromMap(
                                                                  userData));
                                                      firestore
                                                              .FirebaseFirestore
                                                          firesStoreInstance =
                                                          getItInstance<
                                                              firestore
                                                                  .FirebaseFirestore>();
                                                      await firesStoreInstance
                                                          .collection(
                                                              CollectionConsts
                                                                  .users)
                                                          .doc(authResult
                                                              .user!.uid)
                                                          .set({
                                                        "details":
                                                            jsonEncode(userData)
                                                      });
                                                      await getItInstance<
                                                              SharedServiceImpl>()
                                                          .setFirestoreUserId(
                                                              authResult
                                                                  .user!.uid);
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                            "Sign Up with Google to continue",
                                                            style: TextStyle(
                                                                fontSize: Sizes
                                                                    .dimen_18
                                                                    .sp)),
                                                        SizedBox(
                                                          width:
                                                              Sizes.dimen_10.w,
                                                        ),
                                                        Container(
                                                          width:
                                                              Sizes.dimen_50.w,
                                                          height:
                                                              Sizes.dimen_50.h,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              image: DecorationImage(
                                                                  image: CachedNetworkImageProvider(
                                                                      "https://www.freepnglogos.com/uploads/google-logo-png/google-logo-png-suite-everything-you-need-know-about-google-newest-0.png"))),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: Sizes.dimen_30,
                                                  ),
                                                  RichText(
                                                    text: TextSpan(children: [
                                                      TextSpan(
                                                          text:
                                                              "By continuing you agree to the ",
                                                          style: TextStyle(
                                                              color: context
                                                                      .isLightMode()
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white)),
                                                      TextSpan(
                                                          text:
                                                              "terms and conditions ",
                                                          recognizer:
                                                              TapGestureRecognizer()
                                                                ..onTap =
                                                                    () async {
                                                                  String url =
                                                                      AppPolicies
                                                                          .TERMS_LINK;
                                                                  if (await canLaunch(
                                                                      url)) {
                                                                    await launch(
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
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColor
                                                                  .violet)),
                                                      TextSpan(
                                                          text:
                                                              "and acknowledge that you have read the ",
                                                          style: TextStyle(
                                                              color: context
                                                                      .isLightMode()
                                                                  ? Colors.black
                                                                  : Colors
                                                                      .white)),
                                                      TextSpan(
                                                          text:
                                                              "privacy policy.",
                                                          recognizer:
                                                              TapGestureRecognizer()
                                                                ..onTap =
                                                                    () async {
                                                                  print("Tap");
                                                                  String url =
                                                                      AppPolicies
                                                                          .PRIVACY_LINK;
                                                                  if (await canLaunch(
                                                                      url)) {
                                                                    await launch(
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
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColor
                                                                  .violet)),
                                                    ]),
                                                  )
                                                ],
                                              ),
                                            );
                                          });
                                    }
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
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
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child:
                                        Icon(Icons.info, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          ],
                          elevation: 0.0,
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          // floating: true,
                          // expandedHeight: Sizes.dimen_140.h,
                          flexibleSpace:
                              LayoutBuilder(builder: (context, constraints) {
                            // print(constraints.biggest.height);
                            // if(constraints.biggest.height == Sizes.dimen_128){
                            //    title.value = widget.mangaDetails.title!;
                            // } else {
                            //   title.value = '';
                            // }
                            return Stack(
// alignment: Alignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                          imageUrl:
                                              widget.mangaDetails.imageUrl ??
                                                  '',
                                          fit: BoxFit.fitWidth,
                                          color: Colors.black.withOpacity(0.7),
                                          colorBlendMode: BlendMode.darken),
                                    ),
                                  ],
                                ),
                                constraints.biggest.height >=
                                        ScreenUtil.screenHeight / 3 -
                                            kToolbarHeight
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: EdgeInsets.only(
                                            left: Sizes.dimen_14.w,
                                          ),
                                          width: ScreenUtil.screenWidth / 2,
                                          child: Wrap(
                                            children: [
                                              Text(
                                                widget.mangaDetails.title ?? "",
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
                                // constraints.biggest.height >=
                                //         ScreenUtil.screenHeight / 3 -
                                //             kToolbarHeight
                                //     ? Positioned(
                                //         top: Sizes.dimen_70.h,
                                //         left: Sizes.dimen_14.w,
                                //         child: Container(
                                //           width: ScreenUtil.screenWidth - 10,
                                //           child: Wrap(
                                //             clipBehavior: Clip.hardEdge,
                                //             children: [
                                //               Text(
                                //                 mangaInfo!.data.description
                                //                             .trim()
                                //                             .length >
                                //                         300
                                //                     ? mangaInfo!
                                //                             .data.description
                                //                             .trim()
                                //                             .substring(
                                //                                 0, 100) +
                                //                         "..."
                                //                     : mangaInfo!
                                //                         .data.description
                                //                         .trim(),
                                //                 style: TextStyle(
                                //                     color: Colors.white),
                                //               ),
                                //             ],
                                //           ),
                                //         ))
                                //     : Container(),
                              ],
                            );
                          }),
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: Sizes.dimen_2.h,
                                  ),
                                  Text("SUMMARY",
                                      style: TextStyle(
                                          fontSize: Sizes.dimen_18.sp,
                                          fontWeight: FontWeight.w900)),
                                  SizedBox(
                                    height: Sizes.dimen_6.h,
                                  ),
                                  Text(
                                    mangaInfo.data.summary.trim(),
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(),
                                  ),
                                  SizedBox(
                                    height: Sizes.dimen_6.h,
                                  ),
                                  Text("AUTHOR",
                                      style: TextStyle(
                                          fontSize: Sizes.dimen_18.sp,
                                          fontWeight: FontWeight.w900)),
                                  SizedBox(
                                    height: Sizes.dimen_6.h,
                                  ),
                                  Text(
                                    mangaInfo.data.author,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, settingsBloc) {
                          return Container(
                            // color: getTileDefaultColor(settingsBloc.settings.drawChapterColorsFromImage, context),
                            child: ListView.builder(
                                padding: EdgeInsets.all(0.0),
                                itemCount: result.isLoading
                                    ? 1
                                    : mangaInfo != null
                                        ? mangaInfo.data.chapterList.length
                                        : 20,
                                itemBuilder: (ctx, index) {
                                  if (result.hasException) {
                                    return Text(result.exception.toString());
                                  }

                                  if (result.isLoading) {
                                    return Loading();
                                  }
                                  return BlocBuilder<ChaptersReadCubit,
                                          ChaptersReadState>(
                                      builder: (context, chapterReadState) {
                                    return Container(
                                      decoration: BoxDecoration(
                                          color: chapterReadState.chaptersRead
                                                      .indexWhere((element) =>
                                                          element.chapterUrl ==
                                                          mangaInfo!
                                                              .data
                                                              .chapterList[
                                                                  index]
                                                              .chapterUrl) !=
                                                  -1
                                              ? getTileSelectedColor(
                                                  settingsBloc.settings
                                                      .drawChapterColorsFromImage,
                                                  context)
                                              : Colors.transparent),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.only(
                                            left: Sizes.dimen_4),
                                        isThreeLine: true,
                                        onTap: () async {
                                          final DatabaseHelper dbInstance =
                                              getItInstance<DatabaseHelper>();
                                          ChapterRead newChapter = ChapterRead(
                                              mangaUrl: widget
                                                      .mangaDetails.mangaUrl ??
                                                  'none',
                                              chapterUrl: mangaInfo!
                                                  .data
                                                  .chapterList[index]
                                                  .chapterUrl);
                                          RecentlyRead recentlyRead =
                                              RecentlyRead(
                                                  title: widget
                                                          .mangaDetails.title ??
                                                      '',
                                                  mangaUrl: widget.mangaDetails
                                                          .mangaUrl ??
                                                      '',
                                                  imageUrl:
                                                      widget.mangaDetails
                                                              .imageUrl ??
                                                          "",
                                                  chapterUrl:
                                                      mangaInfo
                                                          .data
                                                          .chapterList[index]
                                                          .chapterUrl,
                                                  chapterTitle:
                                                      mangaInfo
                                                          .data
                                                          .chapterList[index]
                                                          .chapterTitle,
                                                  mostRecentReadDate:
                                                      DateTime.now()
                                                          .toString());
                                          List<RecentlyRead> recents = context
                                              .read<RecentsCubit>()
                                              .state
                                              .recents;
                                          List<ChapterRead> chaptersRead =
                                              context
                                                  .read<ChaptersReadCubit>()
                                                  .state
                                                  .chaptersRead;
                                          List<RecentlyRead>
                                              withoutCurrentRead = recents
                                                  .where((element) =>
                                                      element.mangaUrl !=
                                                      recentlyRead.mangaUrl)
                                                  .toList();
                                          List<ChapterRead>
                                              withoutCurrentChapter =
                                              chaptersRead
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
                                                  chapterUrl: mangaInfo
                                                      .data
                                                      .chapterList[index]
                                                      .chapterUrl,
                                                  chapterTitle: mangaInfo
                                                      .data
                                                      .chapterList[index]
                                                      .chapterTitle,
                                                  dateUploaded: mangaInfo
                                                      .data
                                                      .chapterList[index]
                                                      .dateUploaded));
                                        },
                                        subtitle: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 16, 0, 0),
                                          child: Text(
                                            mangaInfo!.data.chapterList[index]
                                                .dateUploaded,
                                            style: TextStyle(
                                                color: context.isLightMode()
                                                    ? AppColor.vulcan
                                                        .withOpacity(0.6)
                                                    : Color(0xffF4E8C1)),
                                          ),
                                        ),
                                        leading: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          child: Container(
                                            // padding: EdgeInsets.all(8),
                                            height: Sizes.dimen_100.h,
                                            width: Sizes.dimen_110.w,
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                            widget.mangaDetails
                                                                    .imageUrl ??
                                                                ''),
                                                    fit: BoxFit.cover)),
                                          ),
                                        ),
                                        title: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(mangaInfo
                                                  .data
                                                  .chapterList[index]
                                                  .chapterTitle
                                                  .replaceAll("-", " ")
                                                  .split(" ")[mangaInfo
                                                          .data
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
                                              mangaInfo.data.chapterList[index]
                                                  .chapterTitle
                                                  .replaceAll("-", " ")
                                                  .split(" ")[mangaInfo.data.chapterList[index].chapterTitle.split("-").indexWhere((element) => element == "chapter") + 2]),
                                        ),
                                      ),
                                    );
                                  });
                                }),
                          );
                        }),
                        Container(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                            children: List.generate(
                                mangaInfo!.data.recommendations.length,
                                (index) {
                              return ScaleAnim(
                                onTap: () {
                                  Navigator.of(context).pushReplacementNamed(
                                      Routes.mangaInfo,
                                      arguments: newestMMdl.Datum(
                                          title: mangaInfo!.data
                                              .recommendations[index].title,
                                          mangaUrl: mangaInfo!.data
                                              .recommendations[index].mangaUrl,
                                          imageUrl: mangaInfo!
                                              .data
                                              .recommendations[index]
                                              .mangaImage));
                                },
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: Sizes.dimen_120,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              Sizes.dimen_4),
                                          child: CachedNetworkImage(
                                            imageUrl: mangaInfo!
                                                    .data
                                                    .recommendations[index]
                                                    .mangaImage ??
                                                '',
                                            imageBuilder:
                                                (context, imageProvider) =>
                                                    Container(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            placeholder: (context, url) =>
                                                NoAnimationLoading(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: Sizes.dimen_4.h,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        mangaInfo!
                                            .data.recommendations[index].title
                                            .trim(),
                                        maxLines: 1,
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: Sizes.dimen_14.sp,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Loading();
          }),
    );
  }
}
