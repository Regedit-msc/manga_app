import 'package:flutter/material.dart';
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
        child: callSvg(
          'assets/tcomic.svg',
          color: context.isLightMode() ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
