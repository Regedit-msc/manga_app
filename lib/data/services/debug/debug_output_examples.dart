/*
Example Debug Output:

This file shows what the debug logging will look like in the console when the app is running in debug mode.

API CALLS:
==========

🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: getMangaPage - Manga Updates
├── Variables:
│   ├── page: 1
└── Timestamp: 2025-08-30T10:30:45.123Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: getMangaPage - Manga Updates
├── Status: ✅ SUCCESS
├── Response Data Keys: [getMangaPage]
├── Data Summary:
│   ├── getMangaPage: Object (3 properties)
└── Timestamp: 2025-08-30T10:30:45.456Z

🔍 MANGA_DEBUG HTTP REQUEST
├── Method: GET
├── URL: https://api.unsplash.com/search/collections?page=1&query=anime
├── Headers:
│   ├── authorization: ***HIDDEN***
└── Timestamp: 2025-08-30T10:30:46.123Z

🔍 MANGA_DEBUG HTTP RESPONSE
├── URL: https://api.unsplash.com/search/collections?page=1&query=anime
├── Status: 200 ✅
├── Headers: [content-type, content-length, server]
├── Body Length: 1234 characters
├── Body Preview: {"results":[{"id":"12345","title":"Anime Collection"...
└── Timestamp: 2025-08-30T10:30:46.456Z

NAVIGATION:
===========

🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-info
├── From: /
├── Arguments: Datum
│   ├── Keys: [title, mangaUrl, mangaSource, imageUrl]
└── Timestamp: 2025-08-30T10:30:47.123Z

🔍 MANGA_DEBUG NAVIGATION
├── Route: /manga-reader
├── From: /manga-info
├── Arguments: ChapterList
│   ├── Value: Instance of 'ChapterList'
└── Timestamp: 2025-08-30T10:30:48.789Z

SEARCH QUERIES:
===============

🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Query
├── Operation: mangaSearch - Search for: "naruto"
├── Variables:
│   ├── term: naruto
└── Timestamp: 2025-08-30T10:30:49.123Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: mangaSearch - Search for: "naruto"
├── Status: ✅ SUCCESS
├── Response Data Keys: [mangaSearch]
├── Data Summary:
│   ├── mangaSearch: Object (2 properties)
└── Timestamp: 2025-08-30T10:30:49.456Z

MUTATIONS:
==========

🔍 MANGA_DEBUG API CALL
├── Type: GraphQL Mutation
├── Operation: addToken
├── Variables:
│   ├── token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
│   ├── userId: 550e8400-e29b-41d4-a716-446655440000
└── Timestamp: 2025-08-30T10:30:50.123Z

🔍 MANGA_DEBUG API RESPONSE
├── Operation: addToken
├── Status: ✅ SUCCESS
├── Response Data Keys: [addFcmToken]
├── Data Summary:
│   ├── addFcmToken: Object (1 properties)
└── Timestamp: 2025-08-30T10:30:50.456Z

ERROR SCENARIOS:
================

🔍 MANGA_DEBUG API RESPONSE
├── Operation: getMangaInfo
├── Status: ❌ ERROR
├── Error: Network error: Connection failed
└── Timestamp: 2025-08-30T10:30:51.123Z

🔍 MANGA_DEBUG HTTP RESPONSE
├── URL: https://api.unsplash.com/search/collections
├── Status: 429 ❌
├── Headers: [retry-after, content-type]
├── Body Length: 156 characters
├── Body: {"error":"Rate limit exceeded","message":"Too many requests"}
└── Timestamp: 2025-08-30T10:30:52.456Z

NOTES:
======
- Logging only appears in DEBUG mode (when kDebugMode is true)
- No logging appears in production builds
- Sensitive data like authorization tokens are hidden or truncated
- Long responses are truncated with preview to avoid console spam
- Navigation arguments show type and basic structure without sensitive data
- All timestamps are in ISO 8601 format for easy parsing

*/
