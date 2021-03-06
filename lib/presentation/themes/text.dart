import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/presentation/themes/colors.dart';

class ThemeText {
  const ThemeText._();

  static TextTheme get _poppinsTextTheme => GoogleFonts.poppinsTextTheme();

  static TextStyle? get _whiteHeadline6 =>
      _poppinsTextTheme.headline6?.copyWith(
        fontSize: Sizes.dimen_20.sp,
        color: Colors.white,
      );

  static TextStyle? get _whiteHeadline5 =>
      _poppinsTextTheme.headline5?.copyWith(
        fontSize: Sizes.dimen_24.sp,
        color: Colors.white,
      );
  static TextStyle? get _darkHeadline5 => _poppinsTextTheme.headline5?.copyWith(
        fontSize: Sizes.dimen_24.sp,
        color: Colors.black,
      );

  static TextStyle? get _darkHeadline6 => _poppinsTextTheme.headline6?.copyWith(
        fontSize: Sizes.dimen_20.sp,
        color: Colors.black,
      );
  static TextStyle? get whiteSubtitle1 => _poppinsTextTheme.subtitle1?.copyWith(
        fontSize: Sizes.dimen_16.sp,
        color: Colors.white,
      );
  static TextStyle? get darkSubtitle1 => _poppinsTextTheme.subtitle1?.copyWith(
        fontSize: Sizes.dimen_16.sp,
        color: Colors.black,
      );

  static TextStyle? get _whiteButton => _poppinsTextTheme.button?.copyWith(
        fontSize: Sizes.dimen_14.sp,
        color: Colors.white,
      );

  static TextStyle? get _darkButton => _poppinsTextTheme.button?.copyWith(
        fontSize: Sizes.dimen_14.sp,
        color: Colors.black,
      );
  static TextStyle? get whiteBodyText2 => _poppinsTextTheme.bodyText2?.copyWith(
        color: Colors.white,
        fontSize: Sizes.dimen_14.sp,
        wordSpacing: 0.25,
        letterSpacing: 0.25,
        height: 1.5,
      );
  static TextStyle? get darkBodyText2 => _poppinsTextTheme.bodyText2?.copyWith(
        color: Colors.black,
        fontSize: Sizes.dimen_14.sp,
        wordSpacing: 0.25,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle? get _darkCaption => _poppinsTextTheme.caption?.copyWith(
        color: AppColor.vulcan,
        fontSize: Sizes.dimen_14.sp,
        wordSpacing: 0.25,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle? get _vulcanHeadline6 =>
      _whiteHeadline6?.copyWith(color: AppColor.vulcan);

  static TextStyle? get _vulcanHeadline5 =>
      _whiteHeadline5?.copyWith(color: AppColor.vulcan);

  static TextStyle? get vulcanSubtitle1 =>
      whiteSubtitle1?.copyWith(color: AppColor.vulcan);

  static TextStyle? get vulcanBodyText2 =>
      whiteBodyText2?.copyWith(color: AppColor.vulcan);

  static TextStyle? get _lightCaption =>
      _darkCaption?.copyWith(color: Colors.white);

  static getTextTheme() => TextTheme(
        headline5: _whiteHeadline5,
        headline6: _whiteHeadline6,
        subtitle1: whiteSubtitle1,
        bodyText2: whiteBodyText2,
        button: _whiteButton,
        caption: _darkCaption,
      );

  static getTextLightTheme() => TextTheme(
        headline5: _darkHeadline5,
        headline6: _darkHeadline6,
        subtitle1: darkSubtitle1,
        bodyText2: darkBodyText2,
        button: _darkButton,
        caption: _lightCaption,
      );
  static getLightTextTheme() => TextTheme(
        headline5: _vulcanHeadline5,
        headline6: _vulcanHeadline6,
        subtitle1: vulcanSubtitle1,
        bodyText2: vulcanBodyText2,
        button: _whiteButton,
        caption: _lightCaption,
      );
}

extension ThemeTextExtension on TextTheme {
  TextStyle? get royalBlueSubtitle1 => subtitle1?.copyWith(
      color: AppColor.royalBlue, fontWeight: FontWeight.w600);

  TextStyle? get greySubtitle1 => subtitle1?.copyWith(color: Colors.grey);

  TextStyle? get violetHeadline6 => headline6?.copyWith(color: AppColor.violet);

  TextStyle? get vulcanBodyText2 =>
      bodyText2?.copyWith(color: AppColor.vulcan, fontWeight: FontWeight.w600);

  TextStyle? get whiteBodyText2 =>
      vulcanBodyText2?.copyWith(color: Colors.white);

  TextStyle? get greyCaption => caption?.copyWith(color: Colors.grey);

  TextStyle? get orangeSubtitle1 =>
      subtitle1?.copyWith(color: Colors.orangeAccent);
}
