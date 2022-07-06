import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/gql_api_models/add_token_model.dart';
import 'package:webcomic/data/models/manga_reader_model.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';

import '../../../main.dart';

abstract class GQLRawApiService {
  Future<dynamic> addToken();
  Future<dynamic> updateToken(String token);
  Future<dynamic> subscribe(String mangaTitle);
  Future<void> removeToken();
  Future<GetMangaReaderData?>? getChapterImages(String chapterUrl);
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
      if (userID == '') {
        await prefs.saveUserID(uuid);
      }
      final QueryResult result = await client.mutate(options);
      if (result.hasException) {
        print(result.exception.toString());
        return;
      } else {
        final AddTokenResponse res = AddTokenResponse.fromMap(result.data);
        print(res.addFcmToken!.tokenId);
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
    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      print(result.exception.toString());
      return;
    } else {
      print("Success");
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
      final QueryResult result = await client.mutate(options);
      if (result.hasException) {
        print(result.exception.toString());
        return;
      } else {
        print("Success");
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
    final QueryResult result = await client.mutate(options);
    if (result.hasException) {
      print(result.exception.toString());
    } else {
      print("Success");
    }
  }

  @override
  Future<GetMangaReaderData?>? getChapterImages(String chapterUrl) async{
    final QueryOptions options = QueryOptions(
      document: parseString(MANGA_READER),
      variables: <String, dynamic>{'chapterUrl': chapterUrl},
    );

    final QueryResult result = await client.query(options);
    if (result.hasException) {
      print(result.exception.toString());
      return null;
    } else {
      dynamic mangaToRead = result.data!["getMangaReader"];
      GetMangaReader mangaReader = GetMangaReader.fromMap(mangaToRead);
      return GetMangaReaderData(chapter: mangaReader.data.chapter, images: mangaReader.data.images, chapterList: mangaReader.data.chapterList);
    }
  }

}
