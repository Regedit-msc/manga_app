import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/data/models/unsplash/unsplash_model.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

abstract class UnSplashApiService {
  Future<List<Result>?>? getImages(int page);
}

class UnsplashApiServiceImpl extends UnSplashApiService {
  final Client httpClient;
  UnsplashApiServiceImpl(this.httpClient);
  @override
  Future<List<Result>?>? getImages(int page) async {
    final String url = ApiConstants.unSplashUrl + "?page=$page&query=anime";

    // Log the HTTP request
    DebugLogger.logHttpRequest(
      method: 'GET',
      url: url,
      headers: {
        HttpHeaders.authorizationHeader: ApiConstants.unSplashApiHeader
      },
    );

    try {
      Response res = await httpClient.get(Uri.parse(url), headers: {
        HttpHeaders.authorizationHeader: ApiConstants.unSplashApiHeader
      });

      // Log the HTTP response
      DebugLogger.logHttpResponse(
        url: url,
        statusCode: res.statusCode,
        headers: res.headers,
        body: res.body,
      );

      if (res.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(res.body);
        print(responseJson);
        List<Result> unsplash =
            List.from(responseJson["results"].map((e) => Result.fromMap(e)));
        return unsplash;
      }
      return null;
    } catch (e) {
      DebugLogger.logInfo('Unsplash API Error: $e', category: 'API_ERROR');
      print(e);
      return null;
    }
  }
}
