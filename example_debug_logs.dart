// This is an example of what the debug logs will look like when running the app
// in debug mode. These logs will appear in the console/terminal output.

/*

=== EXAMPLE DEBUG OUTPUT ===

When you run the app in debug mode and navigate around or make API calls,
you'll see logs like these in your console:

1. APP STARTUP - Navigation to Home:
🔍 MANGA_DEBUG NAVIGATION
├── Route: /
├── Arguments: null
└── Timestamp: 2025-08-30T10:15:30.123Z

2. LOADING MANGA UPDATES - GraphQL Query:
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: getMangaPage - Manga Updates
├── Variables:
│   ├── page: 1
└── Timestamp: 2025-08-30T10:15:30.456Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: getMangaPage - Manga Updates
├── Status: ✅ SUCCESS
├── Response Data Keys: [getMangaPage]
├── Data Summary:
│   ├── getMangaPage: Object (3 properties)
└── Timestamp: 2025-08-30T10:15:31.789Z

3. LOADING BACKGROUND IMAGES - HTTP Request:
🔍 MANGA_DEBUG HTTP REQUEST
├── Method: GET
├── URL: https://api.unsplash.com/search/collections?page=1&query=anime
├── Headers:
│   ├── authorization: ***HIDDEN***
└── Timestamp: 2025-08-30T10:15:32.123Z

🔍 MANGA_DEBUG HTTP RESPONSE
├── URL: https://api.unsplash.com/search/collections?page=1&query=anime
├── Status: 200 ✅
├── Headers: [content-type, cache-control, x-ratelimit-remaining]
├── Body Length: 15678 characters
├── Body Preview: {"total":1234,"total_pages":42,"results":[{"id":"abc123"...
└── Timestamp: 2025-08-30T10:15:32.456Z

4. USER CLICKS ON MANGA - Navigation to Manga Info:
🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-info
├── From: /
├── Arguments: Datum
│   ├── Value: {title: "Naruto", mangaUrl: "/manga/naruto-123", ...}
└── Timestamp: 2025-08-30T10:15:35.789Z

5. LOADING MANGA DETAILS - GraphQL Query:
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: getMangaInfo
├── Variables:
│   ├── source: mangasee
│   ├── mangaUrl: /manga/naruto-123
└── Timestamp: 2025-08-30T10:15:36.123Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: getMangaInfo
├── Status: ✅ SUCCESS
├── Response Data Keys: [getMangaInfo]
├── Data Summary:
│   ├── getMangaInfo: Object (2 properties)
└── Timestamp: 2025-08-30T10:15:36.456Z

6. USER SEARCHES FOR MANGA:
🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-search
├── From: /manga-info
├── Arguments: null
└── Timestamp: 2025-08-30T10:16:00.123Z

🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: mangaSearch
├── Variables:
│   ├── term: "one piece"
└── Timestamp: 2025-08-30T10:16:01.456Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: mangaSearch
├── Status: ✅ SUCCESS
├── Response Data Keys: [mangaSearch]
├── Data Summary:
│   ├── mangaSearch: Object (3 properties)
└── Timestamp: 2025-08-30T10:16:02.789Z

7. ERROR EXAMPLE - Failed API Call:
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Mutation
├── Operation: subscribe
├── Variables:
│   ├── tokenId: abc123
│   ├── mangaTitle: One Piece
└── Timestamp: 2025-08-30T10:16:10.123Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: subscribe
├── Status: ❌ ERROR
├── Error: OperationException(linkException: ServerException(originalException: ...))
└── Timestamp: 2025-08-30T10:16:10.456Z

8. FIREBASE TOKEN OPERATIONS:
🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Mutation
├── Operation: addToken
├── Variables:
│   ├── token: ***HIDDEN*** (Firebase tokens are hidden for security)
│   ├── userId: user-uuid-123
└── Timestamp: 2025-08-30T10:16:15.123Z

=== BENEFITS ===

1. DEBUGGING: See exactly what APIs are failing and why
2. PERFORMANCE: Track slow API calls with timestamps
3. USER FLOW: Follow navigation patterns during development
4. NETWORK ISSUES: Identify connection problems quickly
5. DATA VALIDATION: Verify API responses contain expected data

=== PRODUCTION SAFETY ===

- Logs ONLY appear in debug mode (when kDebugMode = true)
- Sensitive information (tokens, passwords) is hidden
- Zero performance impact in production builds
- No logs in release builds

=== HOW TO USE ===

1. Run app in debug mode: `fvm flutter run --debug`
2. Watch console output for 🔍 MANGA_DEBUG logs
3. Navigate around app and trigger API calls
4. Check logs to debug issues

*/
