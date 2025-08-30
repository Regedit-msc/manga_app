// To parse this JSON data, do
//
//     final addTokenResponse = addTokenResponseFromMap(jsonString);

import 'dart:convert';

AddTokenResponse addTokenResponseFromMap(String str) =>
    AddTokenResponse.fromMap(json.decode(str));

String addTokenResponseToMap(AddTokenResponse data) =>
    json.encode(data.toMap());

class AddTokenResponse {
  AddTokenResponse({
    this.addFcmToken,
  });

  final AddFcmToken? addFcmToken;

  factory AddTokenResponse.fromMap(Map<String, dynamic>? json) =>
      AddTokenResponse(
        addFcmToken: AddFcmToken.fromMap(json!["addFcmToken"]),
      );

  Map<String, dynamic> toMap() => {
        "addFcmToken": addFcmToken!.toMap(),
      };

  @override
  String toString() =>
      'AddTokenResponse(token: ${addFcmToken?.tokenId}, success: ${addFcmToken?.success})';
}

class AddFcmToken {
  AddFcmToken({
    required this.message,
    required this.success,
    required this.tokenId,
  });

  final String message;
  final bool success;
  final String tokenId;

  factory AddFcmToken.fromMap(Map<String, dynamic> json) => AddFcmToken(
        message: json["message"],
        success: json["success"],
        tokenId: json["tokenID"],
      );

  Map<String, dynamic> toMap() => {
        "message": message,
        "success": success,
        "tokenID": tokenId,
      };

  @override
  String toString() =>
      'AddFcmToken(success: ' +
      success.toString() +
      ', tokenId: ' +
      tokenId +
      ')';
}
