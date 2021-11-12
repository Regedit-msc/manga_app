import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:webcomic/data/common/constants/deep_link_constants.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/presentation/router.dart';

abstract class DynamicLinksService {
  Future handleDynamicLinks();
  void handleDeepLink(PendingDynamicLinkData data);
  Future<String> createLink(String url);
}

class DynamicLinkServiceImpl extends DynamicLinksService {
  FirebaseDynamicLinks _instance;
  NavigationServiceImpl _navigationServiceImpl;
  DynamicLinkServiceImpl(this._instance, this._navigationServiceImpl);
  @override
  Future handleDynamicLinks() async {
    final PendingDynamicLinkData? data = await _instance.getInitialLink();
    if (data != null) {
      handleDeepLink(data!);
    }
    _instance.onLink(onSuccess: (PendingDynamicLinkData? dynamicLink) async {
      handleDeepLink(dynamicLink!);
    }, onError: (OnLinkErrorException e) async {
      print('Link Failed: ${e.message}');
    });
  }

  @override
  void handleDeepLink(PendingDynamicLinkData data) {
    final Uri? deepLink = data.link;
    if (deepLink != null) {
      print('_handleDeepLink | deeplink: $deepLink');
      bool isCollection = deepLink.pathSegments.contains("collection") &&
          !deepLink.pathSegments.contains("subcollection");
      bool isSubCollection = deepLink.pathSegments.contains("collection") &&
          deepLink.pathSegments.contains("subcollection");
      if (isCollection) {
        String? collectionId = deepLink.queryParameters['collectionId'];
        if (collectionId != null) {
        } else {}
      } else if (isSubCollection) {
        print("IsSubcollection");
        String? collectionId = deepLink.queryParameters['collectionId'];
        String? subCollectionId = deepLink.queryParameters['subcollectionId'];
        if (collectionId != null && subCollectionId != null) {
          Navigator.pushNamed(
              _navigationServiceImpl.navigationKey.currentContext
                  as BuildContext,
              Routes.subCollection,
              arguments: SubcollectionFields(
                  collectionId: collectionId,
                  subcollectionId: subCollectionId));
        } else {}
      }
    }
  }

  @override
  Future<String> createLink(String url,
      {isSubCollection = false, String title = '', String desc = ''}) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: DeepLinkConstants.baseUrl,
      link: Uri.parse(url),
      androidParameters: AndroidParameters(
        packageName: DeepLinkConstants.packageName,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: isSubCollection ? title : 'Tcomic Link',
        description: isSubCollection ? desc : "",
      ),
    );
    final ShortDynamicLink dynamicUrl = await parameters.buildShortLink();

    return dynamicUrl.shortUrl.toString();
  }
}
