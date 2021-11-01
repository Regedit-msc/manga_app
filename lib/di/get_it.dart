import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcomic/data/common/constants/api_constants.dart';
import 'package:webcomic/data/services/api/gql_api.dart';
import 'package:webcomic/data/services/api/unsplash_api.dart';
import 'package:webcomic/data/services/database/db.dart';
import 'package:webcomic/data/services/deep_link/deep_link.service.dart';
import 'package:webcomic/data/services/navigation/navigation_service.dart';
import 'package:webcomic/data/services/prefs/prefs_service.dart';
import 'package:webcomic/data/services/settings/settings_service.dart';
import 'package:webcomic/data/services/snackbar/snackbar_service.dart';
import 'package:webcomic/presentation/themes/theme_controller.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/chapters_read/chapters_read_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/collection_cards/collection_cards_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_search/manga_search_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_updates/manga_updates_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/recents/recent_manga_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/subcriptions/subscriptions_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/user/user_bloc.dart';

final getItInstance = GetIt.I;

Future init() async {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDynamicLinks _dynamicLinks = FirebaseDynamicLinks.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final http.Client _client = http.Client();
  SharedPreferences sharedPref = await SharedPreferences.getInstance();
  getItInstance.registerSingleton<SharedPreferences>(sharedPref);

  getItInstance.registerLazySingleton<ValueNotifier<GraphQLClient>>(() =>
      ValueNotifier(GraphQLClient(
          link: HttpLink(ApiConstants.httpLink),
          cache: GraphQLCache(store: HiveStore()))));
  getItInstance.registerLazySingleton<http.Client>(() => _client);
  getItInstance.registerSingleton<GraphQLClient>(GraphQLClient(
      link: HttpLink(ApiConstants.httpLink),
      cache: GraphQLCache(store: HiveStore())));
  getItInstance.registerLazySingleton<FirebaseAuth>(() => _auth);
  getItInstance.registerLazySingleton<ImagePicker>(() => _picker);
  getItInstance.registerLazySingleton<GoogleSignIn>(() => _googleSignIn);
  getItInstance
      .registerLazySingleton<FirebaseDynamicLinks>(() => _dynamicLinks);
  getItInstance.registerLazySingleton<FirebaseStorage>(() => _storage);
  getItInstance.registerLazySingleton<FirebaseFirestore>(() => _firestore);
  getItInstance.registerLazySingleton<SharedServiceImpl>(
      () => SharedServiceImpl(prefs: getItInstance()));
  getItInstance.registerLazySingleton<ThemeController>(
      () => ThemeController(getItInstance()));
  getItInstance.registerLazySingleton<DynamicLinkServiceImpl>(
      () => DynamicLinkServiceImpl(getItInstance(), getItInstance()));
  getItInstance.registerLazySingleton<UnsplashApiServiceImpl>(
      () => UnsplashApiServiceImpl(getItInstance()));
  getItInstance.registerLazySingleton<SettingsServiceImpl>(
      () => SettingsServiceImpl(getItInstance()));
  getItInstance
      .registerLazySingleton<SnackbarServiceImpl>(() => SnackbarServiceImpl());
  getItInstance.registerLazySingleton<NavigationServiceImpl>(
      () => NavigationServiceImpl());
  getItInstance.registerLazySingleton<GQLRawApiServiceImpl>(() =>
      GQLRawApiServiceImpl(prefs: getItInstance(), client: getItInstance()));
  getItInstance.registerFactory(
    () => BottomNavigationCubit(),
  );
  getItInstance.registerFactory(
    () => ShowCollectionCubit(),
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
  getItInstance.registerFactory(
    () => UserFromGoogleCubit(),
  );
  getItInstance.registerFactory(
    () => CollectionCardsCubit(),
  );
  getItInstance.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
}
