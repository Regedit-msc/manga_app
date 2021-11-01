import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';
import 'package:webcomic/presentation/ui/other_pages/collections/widgets/newly_added_collections.dart';

class CollectionsView extends StatefulWidget {
  const CollectionsView({Key? key}) : super(key: key);

  @override
  _CollectionsViewState createState() => _CollectionsViewState();
}

class _CollectionsViewState extends State<CollectionsView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    doSetup();
    super.initState();
  }

  void doSetup() {
    bool firstTimeHere =
        getItInstance<SharedServiceImpl>().firstTimeOnCollections();
    if (firstTimeHere) {
      getItInstance<SnackbarServiceImpl>().showSnack(context,
          "Welcome to collections.\n Here can create share and also view yours and others comic collections.\n What are you waiting for? Tap soomething to get the ball rolling. P.S remind me to change this to a dialog with images. Thanks!!");
      getItInstance<SharedServiceImpl>().setFirstTimeOnCollectionsToFalse();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                          width: Sizes.dimen_200.w,
                          height: Sizes.dimen_20.h,
                          color: !context.isLightMode()
                              ? Colors.white
                              : AppColor.vulcan,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: TextField(
                                cursorColor: !context.isLightMode()
                                    ? AppColor.vulcan
                                    : Colors.white,
                                // controller: searchController,
                                onChanged: (v) {
                                  // if (v.length < 3) return;
                                  // onSearchChanged(v, client);
                                },
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !context.isLightMode()
                                        ? AppColor.vulcan
                                        : Colors.white),
                                decoration: new InputDecoration.collapsed(
                                    hintText: 'Search Collections',
                                    hintStyle: TextStyle(
                                        color:
                                            AppColor.bottomNavUnselectedColor)),
                              ),
                            ),
                          )),
                    ),
                  ),
                  ScaleAnim(
                    onTap: () {
                      // Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: BlocBuilder<UserFromGoogleCubit, UserState>(
                          builder: (context, userDetails) {
                        return CircleAvatar(
                          backgroundColor: context.isLightMode()
                              ? AppColor.vulcan
                              : Colors.white,
                          backgroundImage: CachedNetworkImageProvider(
                            userDetails.user.profilePicture,
                          ),
                        );
                      }),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
                child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Just Added",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  NewlyAddedCollections()
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
