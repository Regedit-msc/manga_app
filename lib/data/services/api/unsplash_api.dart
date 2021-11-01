import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/data/models/unsplash/unsplash_model.dart';

abstract class UnSplashApiService {
  Future<List<Result>?>? getImages(int page);
}

class UnsplashApiServiceImpl extends UnSplashApiService {
  final Client httpClient;
  UnsplashApiServiceImpl(this.httpClient);
  @override
  Future<List<Result>?>? getImages(int page) async {
    final String url = ApiConstants.unSplashUrl + "?page=$page&query=anime";
    try {
      Response res = await httpClient.get(Uri.parse(url), headers: {
        HttpHeaders.authorizationHeader: ApiConstants.unSplashApiHeader
      });
      if (res.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(res.body);
        print(responseJson);
        List<Result> unsplash =
            List.from(responseJson["results"].map((e) => Result.fromMap(e)));
        return unsplash;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
