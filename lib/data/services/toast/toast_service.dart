import 'package:fluttertoast/fluttertoast.dart';

abstract class ToastService {
  void showToast(String message, Toast length);
}

class ToastServiceImpl extends ToastService {
  @override
  void showToast(String message, Toast length) {
    Fluttertoast.showToast(msg: message, toastLength: length);
  }
}
