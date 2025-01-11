import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/presentation/themes/colors.dart';

class ThemeText {
  const ThemeText._();

  static TextTheme get _poppinsTextTheme => GoogleFonts.poppinsTextTheme();

  static TextStyle? get _whiteHeadline6 =>
      _poppinsTextTheme.titleLarge?.copyWith(
        fontSize: Sizes.dimen_20.sp,
        color: Colors.white,
      );

  static TextStyle? get _whiteHeadline5 =>
      _poppinsTextTheme.headlineSmall?.copyWith(
        fontSize: Sizes.dimen_24.sp,
        color: Colors.white,
      );
  static TextStyle? get _darkHeadline5 => _poppinsTextTheme.headlineSmall?.copyWith(
        fontSize: Sizes.dimen_24.sp,
        color: Colors.black,
      );

  static TextStyle? get _darkHeadline6 => _poppinsTextTheme.titleLarge?.copyWith(
        fontSize: Sizes.dimen_20.sp,
        color: Colors.black,
      );
  static TextStyle? get whiteSubtitle1 => _poppinsTextTheme.titleMedium?.copyWith(
        fontSize: Sizes.dimen_16.sp,
        color: Colors.white,
      );
  static TextStyle? get darkSubtitle1 => _poppinsTextTheme.titleMedium?.copyWith(
        fontSize: Sizes.dimen_16.sp,
        color: Colors.black,
      );

  static TextStyle? get _whiteButton => _poppinsTextTheme.labelLarge?.copyWith(
        fontSize: Sizes.dimen_14.sp,
        color: Colors.white,
      );

  static TextStyle? get _darkButton => _poppinsTextTheme.labelLarge?.copyWith(
        fontSize: Sizes.dimen_14.sp,
        color: Colors.black,
      );
  static TextStyle? get whiteBodyText2 => _poppinsTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontSize: Sizes.dimen_14.sp,
        wordSpacing: 0.25,
        letterSpacing: 0.25,
        height: 1.5,
      );
  static TextStyle? get darkBodyText2 => _poppinsTextTheme.bodyMedium?.copyWith(
        color: Colors.black,
        fontSize: Sizes.dimen_14.sp,
        wordSpacing: 0.25,
        letterSpacing: 0.25,
        height: 1.5,
      );

  static TextStyle? get _darkCaption => _poppinsTextTheme.bodySmall?.copyWith(
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
        headlineSmall: _whiteHeadline5,
        titleLarge: _whiteHeadline6,
        titleMedium: whiteSubtitle1,
        bodyMedium: whiteBodyText2,
        labelLarge: _whiteButton,
        bodySmall: _darkCaption,
      );

  static getTextLightTheme() => TextTheme(
        headlineSmall: _darkHeadline5,
        titleLarge: _darkHeadline6,
        titleMedium: darkSubtitle1,
        bodyMedium: darkBodyText2,
        labelLarge: _darkButton,
        bodySmall: _lightCaption,
      );
  static getLightTextTheme() => TextTheme(
        headlineSmall: _vulcanHeadline5,
        titleLarge: _vulcanHeadline6,
        titleMedium: vulcanSubtitle1,
        bodyMedium: vulcanBodyText2,
        labelLarge: _whiteButton,
        bodySmall: _lightCaption,
      );
}

extension ThemeTextExtension on TextTheme {
  TextStyle? get royalBlueSubtitle1 => titleMedium?.copyWith(
      color: AppColor.royalBlue, fontWeight: FontWeight.w600);

  TextStyle? get greySubtitle1 => titleMedium?.copyWith(color: Colors.grey);

  TextStyle? get violetHeadline6 => titleLarge?.copyWith(color: AppColor.violet);

  TextStyle? get vulcanBodyText2 =>
      bodyMedium?.copyWith(color: AppColor.vulcan, fontWeight: FontWeight.w600);

  TextStyle? get whiteBodyText2 =>
      vulcanBodyText2?.copyWith(color: Colors.white);

  TextStyle? get greyCaption => bodySmall?.copyWith(color: Colors.grey);

  TextStyle? get orangeSubtitle1 =>
      titleMedium?.copyWith(color: Colors.orangeAccent);
}
