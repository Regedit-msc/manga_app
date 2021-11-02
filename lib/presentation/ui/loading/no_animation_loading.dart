import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';

class NoAnimationLoading extends StatefulWidget {
  const NoAnimationLoading({Key? key}) : super(key: key);

  @override
  _NoAnimationLoadingState createState() => _NoAnimationLoadingState();
}

class _NoAnimationLoadingState extends State<NoAnimationLoading> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.isLightMode() ? Colors.grey[100] : Colors.grey[900],
      body: Center(
        child: callSvg('assets/logo_light.svg',
            color: context.isLightMode() ? Colors.white : Colors.grey,
            width: Sizes.dimen_40.w,
            height: Sizes.dimen_40.h),
      ),
    );
    ;
  }
}
