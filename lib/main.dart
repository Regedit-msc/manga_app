import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/di/get_it.dart' as getIt;
import 'package:webcomic/presentation/index.dart';

/// Firebase messaging instance
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

/// Flutter Local Notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background notification channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'high_importance_channel', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(message.notification!.title);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  await getIt.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  runApp(const Index());
}
