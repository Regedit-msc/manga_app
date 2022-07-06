import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/presentation/themes/colors.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..forward()
          ..repeat();
    final curvedAnim = CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut);
    _animation =
        Tween<double>(begin: 0.0, end: Sizes.dimen_40.h).animate(curvedAnim)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            switch (status) {
              case AnimationStatus.completed:
                _animationController.reverse();
                break;
              case AnimationStatus.dismissed:
                _animationController.forward();
                break;
              default:
                break;
            }
          });

    super.initState();
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          // width: Sizes.dimen_70.w,
          // height: Sizes.dimen_70.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: callSvg(
                  "assets/tcomic.svg",
                  color: context.isLightMode() ? AppColor.violet : Colors.white,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: callSvg("assets/tcomic.svg",
                    color: context.isLightMode()
                        ? AppColor.vulcan
                        : AppColor.violet,
                    height: _animation.value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
