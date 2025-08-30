import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';

/// A lightweight BottomNavigationBar that rebuilds only when relevant state changes.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const List<String> _labels = [
    'HOME',
    'MY',
    'GENRES',
    'SETTINGS',
    'COLLECTIONS',
  ];

  static const List<String> _icons = [
    'assets/Home.svg',
    'assets/User.svg',
    'assets/Favourites.svg',
    'assets/Settings.svg',
    'assets/naruto.svg',
  ];

  static const List<String> _activeIcons = [
    'assets/Home_active.svg',
    'assets/User_active.svg',
    'assets/Favourites_active.svg',
    'assets/Settings_active.svg',
    'assets/sign.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final int index = context.select((BottomNavigationCubit c) => c.state);
    final bool showCollections =
        context.select((ShowCollectionCubit c) => c.state);
    final ThemeState themeState = context.watch<ThemeCubit>().state;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isLight = themeState.themeMode != ThemeMode.dark &&
        theme.brightness == Brightness.light;

    final int itemCount = showCollections ? _labels.length : 4;

    final Color selectedColor = isLight ? scheme.primary : scheme.primary;
    final Color unselectedColor = scheme.onSurfaceVariant;

    return BottomNavigationBar(
      elevation: 2.0,
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      unselectedLabelStyle: TextStyle(fontSize: Sizes.dimen_11_5.sp),
      selectedLabelStyle:
          TextStyle(fontSize: Sizes.dimen_11_5.sp, color: selectedColor),
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
          (isLight ? scheme.surface : AppColor.vulcan),
      items: List.generate(itemCount, (i) {
        final bool isActive = index == i;
        final String asset = isActive ? _activeIcons[i] : _icons[i];
        final Color iconColor = isActive ? selectedColor : unselectedColor;
        return BottomNavigationBarItem(
          tooltip: _labels[i],
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: callSvg(
              asset,
              color: iconColor,
              width: Sizes.dimen_30,
              height: Sizes.dimen_30,
            ),
          ),
          label: _labels[i],
        );
      }),
      onTap: (i) {
        context.read<BottomNavigationCubit>().setPage(i);
      },
    );
  }
}
