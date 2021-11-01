import 'package:flutter/material.dart';

abstract class SnackbarService {
  void showSnack(BuildContext context, String text, {Color? color});
}

class SnackbarServiceImpl extends SnackbarService {
  @override
  void showSnack(BuildContext context, String text, {Color? color}) {
    final snackBar = SnackBar(
      padding: EdgeInsets.all(10.0),
      content: Text(text),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
