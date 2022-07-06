import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webcomic/data/services/toast/toast_service.dart';

abstract class CacheService {
  void clearCache();
  CacheManager getDefaultCacheOptions();
}

class CacheServiceImpl extends CacheService {
  ToastServiceImpl toastServiceImpl;

  CacheServiceImpl(this.toastServiceImpl);
  @override
  void clearCache() {
    DefaultCacheManager().emptyCache();
    imageCache!.clear();
    imageCache!.clearLiveImages();
    toastServiceImpl.showToast(
        "Successfully cleared cached images. ", Toast.LENGTH_SHORT);
  }

  @override
  CacheManager getDefaultCacheOptions() {
    return CacheManager(Config("mangaImagesCache",
        stalePeriod: Duration(days: 15), maxNrOfCacheObjects: 300));
  }
}
