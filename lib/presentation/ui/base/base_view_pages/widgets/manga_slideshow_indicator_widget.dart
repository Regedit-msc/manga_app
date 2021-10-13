import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

class SlideShowIndicator extends StatelessWidget {
  const SlideShowIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Sizes.dimen_60.w,
      height: Sizes.dimen_10.h,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Sizes.dimen_12),
          color: AppColor.somehowGrey),
      child: BlocBuilder<MangaSlideShowCubit, MangaSlideShowState>(
          builder: (context, mangaSlideShowState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: "${mangaSlideShowState.index}",
                    style: ThemeText.whiteBodyText2
                        ?.copyWith(fontSize: Sizes.dimen_10.sp)),
                TextSpan(
                    text: "  / ${mangaSlideShowState.noOfItems}",
                    style: ThemeText.whiteBodyText2?.copyWith(
                        fontSize: Sizes.dimen_10.sp,
                        color: Color.fromRGBO(161, 164, 182, 0.95)))
              ]),
            ),
          ],
        );
      }),
    );
  }
}
