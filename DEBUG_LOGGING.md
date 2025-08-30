# Debug Logging Implementation

This implementation adds comprehensive debug logging for API calls, responses, and navigation when **NOT in production mode** (only when `kDebugMode` is true).

## Features

### 🔍 What Gets Logged (Only in Debug Mode)

1. **GraphQL API Calls & Responses**

   - Operation type (Query/Mutation)
   - Operation name
   - Variables
   - Response data summary
   - Errors (if any)

2. **HTTP API Calls & Responses**

   - HTTP method and URL
   - Headers (sensitive ones hidden)
   - Request/Response body
   - Status codes

3. **Navigation Events**
   - Route names
   - Navigation arguments
   - Previous routes
   - Timestamps

### 📁 Added Files

- `lib/data/services/debug/debug_logger.dart` - Main logging utility
- `lib/data/services/debug/debug_graphql_widgets.dart` - GraphQL logging helpers
- `lib/data/services/navigation/debug_navigation_observer.dart` - Navigation logging
- `lib/data/services/api/debug_http_client.dart` - HTTP request/response logging

### 🔧 Modified Files

- `lib/di/get_it.dart` - Added debug services to dependency injection
- `lib/presentation/index.dart` - Added navigation observer
- `lib/data/services/api/gql_api.dart` - Added GraphQL logging
- `lib/data/services/api/unsplash_api.dart` - Added HTTP logging
- `lib/data/services/navigation/navigation_service.dart` - Added navigation logging
- `lib/presentation/ui/base/base_view_pages/widgets/manga_updates_home.dart` - Example GraphQL logging

## 🚀 How It Works

### Automatic Logging

Most logging happens automatically without code changes:

1. **Navigation**: All navigation events are automatically logged via `DebugNavigationObserver`
2. **HTTP Requests**: All HTTP requests (like Unsplash API) are logged via `DebugHttpClient`
3. **GraphQL Operations**: Direct GraphQL client calls are logged in the API service

### Manual Logging for GraphQL Widgets

For GraphQL widgets, you can use the helper:

```dart
// Before (existing code)
Query(
  options: QueryOptions(
    document: parseString(MANGA_UPDATE),
    variables: {"page": 1}
  ),
  builder: (result, {refetch, fetchMore}) {
    // ... existing code
  },
)

// After (with debug logging)
GraphQLDebugHelper.loggedQuery(
  options: QueryOptions(
    document: parseString(MANGA_UPDATE),
    variables: {"page": 1}
  ),
  operationName: 'getMangaPage - Manga Updates',
  builder: (result, {refetch, fetchMore}) {
    // ... existing code (unchanged)
  },
)
```

## 📊 Example Log Output

### API Call Log

```
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: getMangaPage - Manga Updates
├── Variables:
│   ├── page: 1
└── Timestamp: 2025-08-30T10:30:45.123Z
```

### API Response Log

```
🔍 MANGA_DEBUG API RESPONSE
├── Operation: getMangaPage - Manga Updates
├── Status: ✅ SUCCESS
├── Response Data Keys: [getMangaPage]
├── Data Summary:
│   ├── getMangaPage: Object (3 properties)
└── Timestamp: 2025-08-30T10:30:45.456Z
```

### Navigation Log

```
🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-info
├── From: /
├── Arguments: Datum
│   ├── Value: {title: "Naruto", mangaUrl: "...", ...}
└── Timestamp: 2025-08-30T10:30:50.789Z
```

### HTTP Request Log

```
🔍 MANGA_DEBUG HTTP REQUEST
├── Method: GET
├── URL: https://api.unsplash.com/search/collections?page=1&query=anime
├── Headers:
│   ├── authorization: ***HIDDEN***
└── Timestamp: 2025-08-30T10:31:00.123Z
```

## 🔒 Privacy & Security

- **Production Safe**: Only logs in debug mode (`kDebugMode`)
- **Sensitive Data**: Authorization headers and tokens are hidden
- **Data Truncation**: Long responses are truncated to prevent log overflow
- **No Sensitive Info**: Personal data in API responses is summarized, not fully logged

## 🎯 Benefits

1. **Debug API Issues**: See exactly what APIs are being called and their responses
2. **Track User Flow**: Follow navigation patterns during development
3. **Performance Monitoring**: Identify slow API calls
4. **Error Debugging**: Get detailed error information
5. **Zero Production Impact**: Completely disabled in production builds

## 🛠️ Usage Tips

1. **Check Console**: Look for logs prefixed with `🔍 MANGA_DEBUG`
2. **Filter Logs**: Use your IDE's log filtering with "MANGA_DEBUG"
3. **Monitor Network**: Combine with network monitoring tools
4. **Performance**: Logs include timestamps for timing analysis

## 🔧 Customization

You can customize logging by modifying `debug_logger.dart`:

- Change log prefixes
- Adjust data truncation limits
- Add new log categories
- Modify output format

The logging is designed to be non-intrusive and can be easily extended or modified as needed.
