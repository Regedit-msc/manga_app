import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedService {
  String getUserID();
  Future<void> saveUserID(String userID);
  String getUserToken();
  bool getAddedToken();
  Future<void> saveUserToken(String userToken);
  String getUserThemePreference();
  Future<void> setUserThemePreference(String theme);
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
}
