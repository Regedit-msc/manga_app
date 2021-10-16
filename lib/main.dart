import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/di/get_it.dart' as getIt;
import 'package:webcomic/presentation/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter();
  await getIt.init();
  runApp(const Index());
}
