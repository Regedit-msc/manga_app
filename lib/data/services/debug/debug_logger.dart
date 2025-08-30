import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql/ast.dart';

/// Debug logger utility for tracking API calls, responses, and navigation
/// Only logs when not in production (kDebugMode)
class DebugLogger {
  static const String _tag = '🔍 MANGA_DEBUG';

  /// Check if we should log (only in debug mode)
  static bool get shouldLog => kDebugMode;

  /// Log API call details
  static void logApiCall({
    required String operationType, // 'Query' or 'Mutation'
    required String operationName,
    required Map<String, dynamic>? variables,
    String? endpoint,
  }) {
    if (!shouldLog) return;

    print('\n$_tag API CALL');
    print('├── Type: $operationType');
    print('├── Operation: $operationName');
    if (endpoint != null) print('├── Endpoint: $endpoint');
    if (variables != null && variables.isNotEmpty) {
      print('├── Variables:');
      variables.forEach((key, value) {
        print('│   ├── $key: $value');
      });
    }
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  /// Log API response details
  static void logApiResponse({
    required String operationName,
    required bool hasError,
    String? errorMessage,
    Map<String, dynamic>? data,
    int? statusCode,
  }) {
    if (!shouldLog) return;

    print('\n$_tag API RESPONSE');
    print('├── Operation: $operationName');
    print('├── Status: ${hasError ? '❌ ERROR' : '✅ SUCCESS'}');
    if (statusCode != null) print('├── Status Code: $statusCode');
    if (hasError && errorMessage != null) {
      print('├── Error: $errorMessage');
    }
    if (data != null) {
      print('├── Response Data Keys: ${data.keys.toList()}');
      // Optionally log first level of data structure without exposing sensitive info
      print('├── Data Summary:');
      data.forEach((key, value) {
        if (value is List) {
          print('│   ├── $key: List (${value.length} items)');
        } else if (value is Map) {
          print('│   ├── $key: Object (${value.keys.length} properties)');
        } else {
          // Truncate long strings
          String valueStr = value.toString();
          if (valueStr.length > 100) {
            valueStr = '${valueStr.substring(0, 100)}...';
          }
          print('│   ├── $key: $valueStr');
        }
      });
    }
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  /// Log GraphQL specific details
  static void logGraphQLOperation(QueryOptions options) {
    if (!shouldLog) return;

    // Extract operation name from document
    String operationName = 'Unknown';
    try {
      final document = options.document;
      final definitions = document.definitions;
      if (definitions.isNotEmpty) {
        final firstDef = definitions.first;
        if (firstDef is OperationDefinitionNode) {
          operationName = firstDef.name?.value ?? 'Unnamed Query';
        }
      }
    } catch (e) {
      // Fallback if we can't extract operation name
    }

    logApiCall(
      operationType: 'GraphQL Query',
      operationName: operationName,
      variables: options.variables,
    );
  }

  /// Log GraphQL mutation
  static void logGraphQLMutation(MutationOptions options) {
    if (!shouldLog) return;

    // Extract operation name from document
    String operationName = 'Unknown';
    try {
      final document = options.document;
      final definitions = document.definitions;
      if (definitions.isNotEmpty) {
        final firstDef = definitions.first;
        if (firstDef is OperationDefinitionNode) {
          operationName = firstDef.name?.value ?? 'Unnamed Mutation';
        }
      }
    } catch (e) {
      // Fallback if we can't extract operation name
    }

    logApiCall(
      operationType: 'GraphQL Mutation',
      operationName: operationName,
      variables: options.variables,
    );
  }

  /// Log GraphQL response
  static void logGraphQLResponse(QueryResult result, String operationName) {
    if (!shouldLog) return;

    logApiResponse(
      operationName: operationName,
      hasError: result.hasException,
      errorMessage: result.exception?.toString(),
      data: result.data,
    );
  }

  /// Log page navigation
  static void logNavigation({
    required String routeName,
    String? previousRoute,
    dynamic arguments,
  }) {
    if (!shouldLog) return;

    print('\n$_tag NAVIGATION');
    print('├── Route: $routeName');
    if (previousRoute != null) print('├── From: $previousRoute');
    if (arguments != null) {
      print('├── Arguments: ${arguments.runtimeType}');
      // Log argument details without exposing sensitive data
      if (arguments is Map) {
        print('│   ├── Keys: ${arguments.keys.toList()}');
      } else {
        print(
            '│   ├── Value: ${arguments.toString().length > 100 ? '${arguments.toString().substring(0, 100)}...' : arguments.toString()}');
      }
    }
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  /// Log general debug information
  static void logInfo(String message, {String? category}) {
    if (!shouldLog) return;

    String prefix = category != null ? '$_tag [$category]' : _tag;
    print('\n$prefix INFO');
    print('├── $message');
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  /// Log HTTP requests (for non-GraphQL APIs like Unsplash)
  static void logHttpRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!shouldLog) return;

    print('\n$_tag HTTP REQUEST');
    print('├── Method: $method');
    print('├── URL: $url');
    if (headers != null && headers.isNotEmpty) {
      print('├── Headers:');
      headers.forEach((key, value) {
        // Don't log sensitive headers
        if (key.toLowerCase().contains('authorization') ||
            key.toLowerCase().contains('token') ||
            key.toLowerCase().contains('key')) {
          print('│   ├── $key: ***HIDDEN***');
        } else {
          print('│   ├── $key: $value');
        }
      });
    }
    if (body != null) {
      print(
          '├── Body: ${body.toString().length > 200 ? '${body.toString().substring(0, 200)}...' : body}');
    }
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  /// Log HTTP response
  static void logHttpResponse({
    required String url,
    required int statusCode,
    Map<String, String>? headers,
    String? body,
  }) {
    if (!shouldLog) return;

    print('\n$_tag HTTP RESPONSE');
    print('├── URL: $url');
    print('├── Status: $statusCode ${_getStatusEmoji(statusCode)}');
    if (headers != null && headers.isNotEmpty) {
      print('├── Headers: ${headers.keys.toList()}');
    }
    if (body != null) {
      print('├── Body Length: ${body.length} characters');
      // Show first 300 characters of response body
      if (body.length > 300) {
        print('├── Body Preview: ${body.substring(0, 300)}...');
      } else {
        print('├── Body: $body');
      }
    }
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }

  static String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '❌';
    if (statusCode >= 500) return '💥';
    return '❓';
  }

  /// Log any model via its toString override
  static void logModel(Object? model, {String? label}) {
    if (!shouldLog) return;
    final name = label ?? model?.runtimeType.toString() ?? 'Model';
    print('\n$_tag MODEL');
    print('├── Type: $name');
    print('├── ToString: ${model?.toString()}');
    print('└── Timestamp: ${DateTime.now().toIso8601String()}');
  }
}
