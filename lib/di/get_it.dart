import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';

final getItInstance = GetIt.I;

Future init() async {
  SharedPreferences sharedPref = await SharedPreferences.getInstance();
  getItInstance.registerLazySingleton<SharedPreferences>(() => sharedPref);
  getItInstance.registerLazySingleton<ValueNotifier<GraphQLClient>>(() =>
      ValueNotifier(GraphQLClient(
          link: HttpLink(ApiConstants.httpLink),
          cache: GraphQLCache(store: HiveStore()))));

  getItInstance.registerFactory(
    () => BottomNavigationCubit(),
  );
  getItInstance.registerFactory(
    () => MangaSlideShowCubit(),
  );
  getItInstance.registerFactory(
    () => MangaResultsCubit(),
  );

  getItInstance.registerFactory(
    () => RecentsCubit(),
  );
  getItInstance.registerFactory(
    () => ChaptersReadCubit(),
  );
  getItInstance
      .registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
}
