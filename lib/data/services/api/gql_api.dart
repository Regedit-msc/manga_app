import 'package:gql/language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:webcomic/data/graphql/graphql.dart';
import 'package:webcomic/data/models/gql_api_models/add_token_model.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';

import '../../../main.dart';

abstract class GQLRawApiService {
  Future<dynamic> addToken();
  Future<dynamic> updateToken(String token);
  Future<dynamic> subscribe(String mangaTitle);
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
      return;
    }
  }

  @override
  Future subscribe(String mangaTitle) async {
    String userToken = prefs.getUserToken();
    final MutationOptions options = MutationOptions(
      document: parseString(SUBSCRIBE),
      variables: <String, dynamic>{
        'tokenID': userToken,
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
