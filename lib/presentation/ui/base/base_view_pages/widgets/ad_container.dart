import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webcomic/data/common/extensions/theme_extension.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/ads/ads_bloc.dart';
import 'package:webcomic/presentation/ui/blocs/theme/theme_bloc.dart';

class AdContainer extends StatefulWidget {
  const AdContainer({Key? key}) : super(key: key);

  @override
  _AdContainerState createState() => _AdContainerState();
}

class _AdContainerState extends State<AdContainer> {
  BannerAd? bannerAd;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initAds();
  }

  void initAds() {
    final adState = context.read<AdsCubit>().state;
    adState.initialization.then((value) async {
      setState(() {
        bannerAd = BannerAd(
            adUnitId: adState.bannerId,
            size: AdSize.banner,
            request: AdRequest(),
            listener: adState.adListener)
          ..load();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(builder: (context, themeBloc) {
      return bannerAd != null
          ? Container(
              width: double.infinity,
              color:
                  themeBloc.themeMode != ThemeMode.dark && context.isLightMode()
                      ? Colors.grey[100]
                      : AppColor.vulcan,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 320.0,
                      height: 50.0,
                      child: AdWidget(ad: bannerAd!),
                    ),
                  ],
                ),
              ),
            )
          : Container();
    });
  }
}
