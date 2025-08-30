import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/data/common/extensions/size_extension.dart';
import 'package:webcomic/data/common/svg_util/svg_util.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/show_collection_view/show_collection_view_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';
import 'package:webcomic/presentation/widgets/download/floating_download_progress.dart';

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

    final Color barColor = theme.bottomNavigationBarTheme.backgroundColor ??
        (isLight ? scheme.surface : AppColor.vulcan);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, -2),
              )
            ],
            border: Border.all(
              color: isLight ? Colors.black12 : Colors.white10,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BottomNavigationBar(
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: index,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              selectedFontSize: Sizes.dimen_11_5.sp,
              unselectedFontSize: Sizes.dimen_11_5.sp,
              backgroundColor: Colors.transparent,
              items: List.generate(itemCount, (i) {
                final bool isActive = index == i;
                final String asset = isActive ? _activeIcons[i] : _icons[i];
                final Color iconColor =
                    isActive ? selectedColor : unselectedColor;
                return BottomNavigationBarItem(
                  tooltip: _labels[i],
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? selectedColor.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: i == 1 // MY tab - add download notification badge
                          ? DownloadNotificationBadge(
                              child: callSvg(
                                asset,
                                color: iconColor,
                                width: Sizes.dimen_24,
                                height: Sizes.dimen_24,
                              ),
                            )
                          : callSvg(
                              asset,
                              color: iconColor,
                              width: Sizes.dimen_24,
                              height: Sizes.dimen_24,
                            ),
                    ),
                  ),
                  label: _labels[i],
                );
              }),
              onTap: (i) {
                context.read<BottomNavigationCubit>().setPage(i);
              },
            ),
          ),
        ),
      ),
    );
  }
}
