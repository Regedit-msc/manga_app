import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/screen_util/screen_util.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/fade_page_route_builder.dart';
import 'package:webcomic/presentation/router.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/themes/text.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/manga_slideshow/manga_slideshow_bloc.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

class Index extends StatefulWidget {
  const Index({Key? key}) : super(key: key);

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  late BottomNavigationCubit _bottomNavigationCubit;
  late MangaSlideShowCubit _mangaSlideShowCubit;

  @override
  void initState() {
    super.initState();
    _bottomNavigationCubit = getItInstance<BottomNavigationCubit>();
    _mangaSlideShowCubit = getItInstance<MangaSlideShowCubit>();
  }

  @override
  void dispose() {
    _bottomNavigationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init();
    return GraphQLProvider(
      client: getItInstance<ValueNotifier<GraphQLClient>>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BottomNavigationCubit>.value(
              value: _bottomNavigationCubit),
          BlocProvider<MangaSlideShowCubit>.value(value: _mangaSlideShowCubit),
        ],
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Manga App',
          theme: ThemeData(
              scaffoldBackgroundColor: AppColor.vulcan,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              textTheme: ThemeText.getTextTheme(),
              appBarTheme: const AppBarTheme(elevation: 0)),
          darkTheme: ThemeData.dark(),
          initialRoute: Routes.initRoute,
          onGenerateRoute: (RouteSettings settings) {
            final routes = CRouter.getRoutes(settings);
            final WidgetBuilder? builder = routes[settings.name];
            return FadePageRouteBuilder(
              builder: builder!,
              settings: settings,
            );
          },
          builder: (context, child) {
            return child!;
          },
        ),
      ),
    );
  }
}