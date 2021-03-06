import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedService {
  String getUserID();
  Future<void> saveUserID(String userID);
  String getUserToken();
  bool getAddedToken();
  Future<void> saveUserToken(String userToken);
  String getUserThemePreference();
  Future<void> setUserThemePreference(String theme);
  String? getGoogleDetails();
  Future<void> saveUserDetails(String userDetailsStringified);
  Future<void> setFirestoreUserId(String userId);
  String getFirestoreUserId();
  String? getUnSplashLinks();
  bool firstTimeOnCollections();
  Future<void> saveUnsplashLinks(String links);
  Future<void> setFirstTimeOnCollectionsToFalse();
  String? getSettings();
  Future<void> setSettings(String settings);
  Future<void> addDownloadedMangaDetails(String details);
  String getDownloadedMangaDetails();
}

class SharedServiceImpl extends SharedService {
  SharedPreferences prefs;
  SharedServiceImpl({required this.prefs});

  @override
  String getUserID() {
    return prefs.getString("USERID") ?? '';
  }

  @override
  Future<void> saveUserID(String userID) async {
    await prefs.setString("USERID", userID);
  }

  @override
  String getUserToken() {
    return prefs.getString("USER_TOKEN") ?? "";
  }

  @override
  Future<void> saveUserToken(String userToken) async {
    await prefs.setBool("ADDED_TOKEN", true);
    await prefs.setString("USER_TOKEN", userToken);
  }

  @override
  bool getAddedToken() {
    return prefs.getBool("ADDED_TOKEN") ?? false;
  }

  @override
  String getUserThemePreference() {
    return prefs.getString("THEME_PREFERENCE") ?? 'system';
  }

  @override
  Future<void> setUserThemePreference(String theme) async {
    await prefs.setString("THEME_PREFERENCE", theme);
  }

  @override
  String? getGoogleDetails() {
    return prefs.getString("GOOGLE_DETAILS") ?? null;
  }

  @override
  Future<void> saveUserDetails(String userDetailsStringified) async {
    await prefs.setString("GOOGLE_DETAILS", userDetailsStringified);
  }

  @override
  String getFirestoreUserId() {
    return prefs.getString("FIRESTORE_USER_ID") ?? "";
  }

  @override
  Future<void> setFirestoreUserId(String userId) async {
    await prefs.setString("FIRESTORE_USER_ID", userId);
  }

  @override
  String? getUnSplashLinks() {
    return prefs.getString("UNSPLASH_LINKS") ?? null;
  }

  @override
  Future<void> saveUnsplashLinks(String links) async {
    await prefs.setString("UNSPLASH_LINKS", links);
  }

  @override
  bool firstTimeOnCollections() {
    return prefs.getBool("FIRST_TIME_ON_COLLECTIONS") ?? true;
  }

  @override
  Future<void> setFirstTimeOnCollectionsToFalse() async {
    await prefs.setBool("FIRST_TIME_ON_COLLECTIONS", false);
  }

  @override
  String? getSettings() {
    return prefs.getString("SETTINGS") ?? null;
  }

  @override
  Future<void> setSettings(String settings) async {
    await prefs.setString("SETTINGS", settings);
  }

  @override
  Future<void> addDownloadedMangaDetails(String details) async{
    await prefs.setString("DOWNLOADED_MANGA", details);
  }
  @override
  String getDownloadedMangaDetails() {
    return prefs.getString("DOWNLOADED_MANGA")?? '';
  }
}
