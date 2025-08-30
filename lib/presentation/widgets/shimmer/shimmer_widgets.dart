import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox(
      {super.key,
      this.width = double.infinity,
      required this.height,
      this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    final highlight =
        Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15);
    final child = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlight,
      child: child,
    );
  }
}

Widget shimmerBanner({double height = 220, BorderRadius? radius}) => ShimmerBox(
    height: height, borderRadius: radius ?? BorderRadius.circular(16));

Widget shimmerChips({int count = 6}) {
  return SizedBox(
    height: 40,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, __) => const ShimmerBox(
          width: 90,
          height: 34,
          borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
  );
}

Widget shimmerHorizontalCards({
  int count = 6,
  double cardWidth = 150,
  double imageHeight = 200,
  bool withTitle = true,
}) {
  return SizedBox(
    height: imageHeight + (withTitle ? 36 : 0),
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
                height: 200,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            if (withTitle) const SizedBox(height: 8),
            if (withTitle)
              const ShimmerBox(
                  height: 16,
                  width: 120,
                  borderRadius: BorderRadius.all(Radius.circular(4))),
          ],
        ),
      ),
    ),
  );
}

Widget shimmerRows(
    {int count = 5, double imageWidth = 70, double imageHeight = 50}) {
  return Column(
    children: List.generate(
        count,
        (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  ShimmerBox(
                      width: imageWidth,
                      height: imageHeight,
                      borderRadius: BorderRadius.circular(6)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                            height: 16,
                            width: double.infinity,
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        SizedBox(height: 6),
                        ShimmerBox(
                            height: 12,
                            width: 140,
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                      ],
                    ),
                  )
                ],
              ),
            )),
  );
}
