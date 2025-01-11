import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as ln;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import '../../../main.dart';

Future<String> _downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final Response response = await get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

class NotificationService {
  static showNotification(description, body, payload) async {
    var androidDetails = const ln.AndroidNotificationDetails(
        'In App Notifications', // id
        'In App Notifications',
        importance: ln.Importance.max,
        priority: ln.Priority.high);
    var iosDetails = ln.DarwinNotificationDetails();
    var generalNotificationDetails =
        ln.NotificationDetails(android: androidDetails, iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(
        0, description, body, generalNotificationDetails,
        payload: payload);
  }

  static Future<void> showBigPictureNotification(
      description, body, imageUrl) async {
    final String bigPicturePath =
        await _downloadAndSaveFile(imageUrl, 'bigPicture');
    final ln.BigPictureStyleInformation bigPictureStyleInformation =
        ln.BigPictureStyleInformation(ln.FilePathAndroidBitmap(bigPicturePath),
            contentTitle: '$description',
            htmlFormatContentTitle: false,
            summaryText: '$body',
            htmlFormatSummaryText: false);
    final ln.AndroidNotificationDetails androidNotificationDetails =
        ln.AndroidNotificationDetails(
            'In App Notifications', // id
            'In App Notifications',
            importance: ln.Importance.max,
            priority: ln.Priority.high,
            styleInformation: bigPictureStyleInformation);
    var iosDetails = ln.DarwinNotificationDetails();
    final ln.NotificationDetails notificationDetails = ln.NotificationDetails(
        android: androidNotificationDetails, iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(
        0, '$description', '$body', notificationDetails);
  }
}
