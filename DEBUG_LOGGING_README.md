# Debug Logging System

This document describes the debug logging system that tracks API calls, responses, and navigation when the app is not in production mode.

## Overview

The debug logging system provides comprehensive tracking of:

- GraphQL API calls and responses
- HTTP requests and responses (Unsplash API)
- Page navigation with route details
- Error scenarios and debugging information

**Important**: Logging only occurs in **DEBUG mode** (`kDebugMode = true`). No logging appears in production builds.

## Features

### 1. API Call Logging

- **GraphQL Operations**: Queries and mutations with variables
- **HTTP Requests**: REST API calls with headers and body
- **Response Tracking**: Success/error status, data structure, and timing
- **Error Handling**: Detailed error messages and stack traces

### 2. Navigation Logging

- **Route Changes**: Track page navigation with route names
- **Arguments**: Log navigation arguments (safely, without sensitive data)
- **Navigation Flow**: See the complete user journey through the app

### 3. Security Features

- **Sensitive Data Protection**: Authorization headers and tokens are hidden
- **Data Truncation**: Long responses are truncated to prevent console spam
- **Production Safety**: Zero logging overhead in release builds

## Implementation

### Core Components

1. **`DebugLogger`** (`lib/data/services/debug/debug_logger.dart`)

   - Main logging utility with static methods
   - Handles all types of logging (API, navigation, etc.)

2. **`DebugHttpClient`** (`lib/data/services/api/debug_http_client.dart`)

   - HTTP client wrapper that logs requests/responses
   - Used for Unsplash API calls

3. **`DebugNavigationObserver`** (`lib/data/services/navigation/debug_navigation_observer.dart`)

   - Navigation observer that tracks route changes
   - Logs navigation events automatically

4. **`GraphQLDebugHelper`** (`lib/data/services/debug/debug_graphql_widgets.dart`)
   - Helper for wrapping GraphQL widgets with logging
   - Provides logged versions of Query and Mutation widgets

### Integration Points

The system is integrated at these key points:

1. **Dependency Injection** (`lib/di/get_it.dart`)

   - HTTP client wrapped with debug logging
   - Navigation observer registered

2. **Main App** (`lib/presentation/index.dart`)

   - Navigation observer added to MaterialApp

3. **GraphQL Services** (`lib/data/services/api/gql_api.dart`)

   - All GraphQL operations logged

4. **HTTP APIs** (`lib/data/services/api/unsplash_api.dart`)

   - REST API calls logged

5. **Navigation Service** (`lib/data/services/navigation/navigation_service.dart`)
   - Manual navigation calls logged

## Usage Examples

### Manual API Logging

```dart
// Log a GraphQL query
DebugLogger.logApiCall(
  operationType: 'GraphQL Query',
  operationName: 'getMangaInfo',
  variables: {'mangaUrl': '/some-manga'},
);

// Log an HTTP request
DebugLogger.logHttpRequest(
  method: 'GET',
  url: 'https://api.example.com/data',
  headers: {'authorization': 'Bearer token'},
);
```

### Using Debug GraphQL Widgets

```dart
// Instead of regular Query widget
Query(
  options: QueryOptions(document: parseString(MANGA_SEARCH)),
  builder: (result, {refetch, fetchMore}) => Widget(),
)

// Use logged version
GraphQLDebugHelper.loggedQuery(
  options: QueryOptions(document: parseString(MANGA_SEARCH)),
  operationName: 'Manga Search',
  builder: (result, {refetch, fetchMore}) => Widget(),
)
```

### Manual Navigation Logging

```dart
// Navigation is automatically logged, but you can add custom logs
DebugLogger.logNavigation(
  routeName: '/custom-route',
  arguments: customData,
);
```

## Sample Output

See `debug_output_examples.dart` for detailed examples of what the logging output looks like in the console.

### API Call Example

```
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: getMangaPage - Manga Updates
├── Variables:
│   ├── page: 1
└── Timestamp: 2025-08-30T10:30:45.123Z
```

### Navigation Example

```
🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-info
├── From: /
├── Arguments: Datum
│   ├── Keys: [title, mangaUrl, mangaSource, imageUrl]
└── Timestamp: 2025-08-30T10:30:47.123Z
```

## Configuration

The system automatically detects debug mode using Flutter's `kDebugMode` constant. No additional configuration is required.

### Customizing Log Output

You can customize the logging behavior by modifying the methods in `DebugLogger`:

```dart
// Add custom category logging
DebugLogger.logInfo('Custom debug message', category: 'MY_FEATURE');

// Control data truncation limits
// Modify the truncation logic in DebugLogger methods
```

## Troubleshooting

### No Logs Appearing

- Ensure you're running in debug mode (`flutter run` not `flutter run --release`)
- Check that `kDebugMode` is true
- Verify the debug observer is registered in MaterialApp

### Too Much Output

- The system automatically truncates long responses
- You can adjust truncation limits in `DebugLogger` methods
- Consider filtering logs by category or operation name

### Missing API Logs

- Ensure the GraphQL client uses the modified service
- Check that HTTP client is wrapped with `DebugHttpClient`
- Verify the logging calls are properly integrated

## Performance Impact

- **Debug Mode**: Minimal impact - logging is designed to be lightweight
- **Production Mode**: Zero impact - all logging code is removed by Flutter's tree shaking
- **Memory Usage**: Logs are printed to console and not stored in memory

## Security Considerations

- Authorization headers and tokens are automatically hidden
- Long data payloads are truncated
- No sensitive user data is logged
- Production builds have no logging code

## Future Enhancements

Potential improvements to consider:

1. **Log Filtering**: Add ability to filter logs by operation type or name
2. **Log Export**: Save logs to file for analysis
3. **Performance Metrics**: Add timing information for API calls
4. **Custom Categories**: More granular categorization of log types
5. **Visual Indicators**: Add colors or icons to different log types in supporting terminals
