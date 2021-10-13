import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

final getItInstance = GetIt.I;
Future init() async {
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
}
