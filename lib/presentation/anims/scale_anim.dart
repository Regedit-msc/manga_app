import 'package:flutter/material.dart';

typedef CallBack = void Function();

class ScaleAnim extends StatefulWidget {
  final Widget child;
  final CallBack? onTap;

  const ScaleAnim({Key? key, required this.child, this.onTap})
      : super(key: key);

  @override
  _ScaleAnimState createState() => _ScaleAnimState();
}

class _ScaleAnimState extends State<ScaleAnim> with TickerProviderStateMixin {
  late AnimationController animController;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    animController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() {
        if (!mounted) return;
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animController.reset();
        }
      });
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
        if (animController.isAnimating) {
          animController.reset();
          animController.forward();
          return;
        }
        animController.forward();
        widget.onTap!();
      },
      key: UniqueKey(),
      child: AnimatedBuilder(
          animation: scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
                scale: scaleAnimation.value, child: widget.child);
          }),
    );
  }
}
