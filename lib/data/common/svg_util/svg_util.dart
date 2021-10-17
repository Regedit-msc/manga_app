import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget callSvg(path, {Color? color, double? width, double? height}) {
  return SvgPicture.asset(
    path,
    color: color,
    width: width,
    height: height,
  );
}
