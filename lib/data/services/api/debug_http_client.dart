import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webcomic/data/services/debug/debug_logger.dart';

/// Custom HTTP client that logs requests and responses in debug mode
class DebugHttpClient extends http.BaseClient {
  final http.Client _inner;

  DebugHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Log the request
    DebugLogger.logHttpRequest(
      method: request.method,
      url: request.url.toString(),
      headers: request.headers,
      body: _getRequestBody(request),
    );

    final response = await _inner.send(request);

    // Convert response to get body for logging
    final responseBytes = await response.stream.toBytes();
    final responseBody = utf8.decode(responseBytes);

    // Log the response
    DebugLogger.logHttpResponse(
      url: request.url.toString(),
      statusCode: response.statusCode,
      headers: response.headers,
      body: responseBody,
    );

    // Return a new streamed response with the consumed bytes
    return http.StreamedResponse(
      Stream.fromIterable([responseBytes]),
      response.statusCode,
      contentLength: responseBytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  dynamic _getRequestBody(http.BaseRequest request) {
    if (request is http.Request) {
      return request.body;
    }
    return null;
  }
}
