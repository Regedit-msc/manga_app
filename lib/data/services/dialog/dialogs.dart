import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/di/get_it.dart';

abstract class DialogService {
   NoNetWorkDialog(dynamic refetch);
}

class DialogServiceImpl extends DialogService  {
     NoNetWorkDialog(dynamic refetch) async{
       await showDialog(
        barrierColor: Colors.transparent,
        context: getItInstance<NavigationServiceImpl>().navigationKey.currentContext!,
        barrierDismissible: true,
        builder: (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(
              vertical: 0.0,
              horizontal: 0.0,
            ),
            elevation:0.0,
            insetAnimationCurve: Curves.ease,
            insetAnimationDuration: Duration(seconds: 0),
            backgroundColor: Colors.white,
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5)),
                height: Sizes.dimen_100.h,
                width: Sizes.dimen_350.w,
                padding: EdgeInsets.all(Sizes.dimen_4.w),
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        alignment: Alignment.center,
                        width: Sizes.dimen_350.w,
                        child: Text(
                          'No internet connnection',
                          style: TextStyle(color: Colors.black, fontSize: Sizes.dimen_15.sp),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: Sizes.dimen_350.w,
                        child: TextButton(
                          onPressed: () {
                            refetch;
                          },
                          child: Text(
                            'Retry',
                            style: TextStyle(color: Colors.black, fontSize: Sizes.dimen_15.sp),
                          ),
                        ),
                      ),
                    )
                  ],
                ))));
  }
}