import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/gql_api_models/add_token_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

import '../../../main.dart';

abstract class GQLRawApiService {
  Future<dynamic> addToken();
  Future<dynamic> updateToken(String token);
  Future<dynamic> subscribe(String mangaTitle);
  Future<void> removeToken();
  Future<GetMangaReaderData?>? getChapterImages(
      String chapterUrl, String source);
}

class GQLRawApiServiceImpl extends GQLRawApiService {
  GraphQLClient client;
  SharedServiceImpl prefs;
  GQLRawApiServiceImpl({required this.client, required this.prefs});
  @override
  Future addToken() async {
    String uuid = const Uuid().v4();
    await firebaseMessaging.getToken().then((value) async {
      String userID = prefs.getUserID();
      final MutationOptions options = MutationOptions(
        document: parseString(ADD_TOKEN),
        variables: <String, dynamic>{
          'token': value,
          'userId': userID != "" ? userID : uuid
        },
      );

      // Log the mutation
      DebugLogger.logGraphQLMutation(options);

      if (userID == '') {
        await prefs.saveUserID(uuid);
      }
      final QueryResult result = await client.mutate(options);

      // Log the response
      DebugLogger.logGraphQLResponse(result, 'addToken');

      if (result.hasException) {
        print(result.exception.toString());
        return;
      } else {
        final AddTokenResponse res = AddTokenResponse.fromMap(result.data);
        DebugLogger.logModel(res, label: 'AddTokenResponse');
        await prefs.saveUserToken(res.addFcmToken!.tokenId);
        return;
      }
    });
  }

  @override
  Future updateToken(String token) async {
    String userID = prefs.getUserID();
    final MutationOptions options = MutationOptions(
      document: parseString(ADD_TOKEN),
      variables: <String, dynamic>{'token': token, 'userId': userID},
    );

    // Log the mutation
    DebugLogger.logGraphQLMutation(options);

    final QueryResult result = await client.mutate(options);

    // Log the response
    DebugLogger.logGraphQLResponse(result, 'updateToken');

    if (result.hasException) {
      print(result.exception.toString());
      return;
    } else {
      DebugLogger.logInfo('Update token success');
      prefs.saveUserToken('');
      return;
    }
  }

  @override
  Future subscribe(String mangaTitle) async {
    String userToken = prefs.getUserToken();
    if (userToken != '') {
      final MutationOptions options = MutationOptions(
        document: parseString(SUBSCRIBE),
        variables: <String, dynamic>{
          'tokenId': userToken,
          'mangaTitle': mangaTitle
        },
      );

      // Log the mutation
      DebugLogger.logGraphQLMutation(options);

      final QueryResult result = await client.mutate(options);

      // Log the response
      DebugLogger.logGraphQLResponse(result, 'subscribe');

      if (result.hasException) {
        print(result.exception.toString());
        return;
      } else {
        DebugLogger.logInfo('Subscribe success');
        return;
      }
    }
  }

  @override
  Future<void> removeToken() async {
    String userID = prefs.getUserID();
    final MutationOptions options = MutationOptions(
      document: parseString(REMOVE_TOKEN),
      variables: <String, dynamic>{'userId': userID},
    );

    // Log the mutation
    DebugLogger.logGraphQLMutation(options);

    final QueryResult result = await client.mutate(options);

    // Log the response
    DebugLogger.logGraphQLResponse(result, 'removeToken');

    if (result.hasException) {
      print(result.exception.toString());
    } else {
      DebugLogger.logInfo('Remove token success');
    }
  }

  @override
  Future<GetMangaReaderData?>? getChapterImages(
      String chapterUrl, String source) async {
    final QueryOptions options = QueryOptions(
      document: parseString(MANGA_READER),
      variables: <String, dynamic>{
        'chapterUrl': chapterUrl,
        'source': source,
      },
    );

    // Log the query
    DebugLogger.logGraphQLOperation(options);

    final QueryResult result = await client.query(options);

    // Log the response
    DebugLogger.logGraphQLResponse(result, 'getChapterImages');

    if (result.hasException) {
      print(result.exception.toString());
      return null;
    } else {
      dynamic mangaToRead = result.data!["getMangaReader"];
      GetMangaReader mangaReader = GetMangaReader.fromMap(mangaToRead);
      DebugLogger.logModel(mangaReader, label: 'GetMangaReader');
      return GetMangaReaderData(
          chapter: mangaReader.data.chapter,
          images: mangaReader.data.images,
          chapterList: mangaReader.data.chapterList);
    }
  }
}
