import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';
import 'package:webcomic/presentation/themes/theme_controller.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_updates/manga_updates_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';

final getItInstance = GetIt.I;

Future init() async {
  SharedPreferences sharedPref = await SharedPreferences.getInstance();
  getItInstance.registerSingleton<SharedPreferences>(sharedPref);
  getItInstance.registerLazySingleton<ValueNotifier<GraphQLClient>>(() =>
      ValueNotifier(GraphQLClient(
          link: HttpLink(ApiConstants.httpLink),
          cache: GraphQLCache(store: HiveStore()))));

  getItInstance.registerSingleton<GraphQLClient>(GraphQLClient(
      link: HttpLink(ApiConstants.httpLink),
      cache: GraphQLCache(store: HiveStore())));

  getItInstance
      .registerLazySingleton(() => SharedServiceImpl(prefs: getItInstance()));
  getItInstance.registerLazySingleton(() => ThemeController(getItInstance()));
  getItInstance
      .registerLazySingleton(() => SettingsServiceImpl(getItInstance()));
  getItInstance.registerLazySingleton(() =>
      GQLRawApiServiceImpl(prefs: getItInstance(), client: getItInstance()));
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
  getItInstance.registerFactory(
    () => SubsCubit(),
  );
  getItInstance.registerFactory(
    () => MangaUpdatesCubit(),
  );
  getItInstance.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
}
