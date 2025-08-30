import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';

/// Simple utility to wrap existing GraphQL operations with logging
class GraphQLDebugHelper {
  /// Log and execute a GraphQL query
  static Widget loggedQuery({
    Key? key,
    required QueryOptions options,
    required QueryBuilder builder,
    String? operationName,
  }) {
    // Log the query
    DebugLogger.logGraphQLOperation(options);

    return Query(
      key: key,
      options: options,
      builder: (QueryResult result, {Refetch? refetch, FetchMore? fetchMore}) {
        // Log the response
        DebugLogger.logGraphQLResponse(
            result, operationName ?? 'GraphQL Query');

        // Call the original builder
        return builder(result, refetch: refetch, fetchMore: fetchMore);
      },
    );
  }

  /// Log and execute a GraphQL mutation
  static Widget loggedMutation({
    Key? key,
    required MutationOptions options,
    required MutationBuilder builder,
    String? operationName,
  }) {
    // Log the mutation
    DebugLogger.logApiCall(
      operationType: 'GraphQL Mutation',
      operationName: operationName ?? 'Unknown Mutation',
      variables: options.variables,
    );

    return Mutation(
      key: key,
      options: options,
      builder: (RunMutation runMutation, QueryResult? result) {
        return builder(
          (Map<String, dynamic> variables, {Object? optimisticResult}) {
            // Log the mutation execution
            DebugLogger.logApiCall(
              operationType: 'GraphQL Mutation Execution',
              operationName: operationName ?? 'Unknown Mutation',
              variables: variables,
            );

            return runMutation(variables, optimisticResult: optimisticResult);
          },
          result,
        );
      },
    );
  }
}
