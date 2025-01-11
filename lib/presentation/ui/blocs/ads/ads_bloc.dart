// import 'package:bloc/bloc.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class AdsState {
//   AdManagerBannerAdListener _adListener = AdManagerBannerAdListener(
//     onAdLoaded: (Ad ad) {},
//     onAdFailedToLoad: (Ad ad, LoadAdError error) {
//       ad.dispose();
//     },
//     onAdOpened: (Ad ad) => print('Ad opened.'),
//     onAdClosed: (Ad ad) => print('Ad closed.'),
//     onAdImpression: (Ad ad) => print('Ad impression.'),
//     onAppEvent: (ad, name, data) =>
//         print('App event : ${ad.adUnitId}, $name, $data.'),
//   );
//   AdManagerBannerAdListener get adListener => _adListener;
//   String get bannerId => bool.fromEnvironment('dart.vm.product')
//       ? "ca-app-pub-7919978113699962/3698717685"
//       : "ca-app-pub-3940256099942544/6300978111";
//   Future<InitializationStatus> initialization;
//   AdsState({required this.initialization});
// }
//
// class AdsCubit extends Cubit<AdsState> {
//   Future<InitializationStatus> initialization;
//   AdsCubit({required this.initialization})
//       : super(AdsState(initialization: initialization));
// }
