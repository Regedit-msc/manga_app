import 'package:flutter/material.dart';
import 'package:webcomic/presentation/anims/scale_anim.dart';

class ContinuousScaleAnim extends StatefulWidget {
  final Widget child;
  final CallBack? onTap;

  const ContinuousScaleAnim({Key? key, required this.child, this.onTap})
      : super(key: key);

  @override
  _ContinuousScaleAnimState createState() => _ContinuousScaleAnimState();
}

class _ContinuousScaleAnimState extends State<ContinuousScaleAnim>
    with TickerProviderStateMixin {
  late AnimationController animController;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    animController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )
      ..forward()
      ..addListener(() {
        if (!mounted) return;
        setState(() {});
      })
      ..repeat();
    scaleAnimation = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0), weight: 50)
    ]).animate(animController);
    super.initState();
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap!();
      },
      key: Key("notification"),
      child: AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
                scale: scaleAnimation.value, child: widget.child);
          }),
    );
  }
}
