import 'package:flutter/foundation.dart';

abstract final class AdConfig {
  static const _testBannerId = 'ca-app-pub-3940256099942544/9214589741';
  static const _productionBannerId = 'ca-app-pub-3635529617309575/8428726334';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _productionInterstitialId =
      'ca-app-pub-3635529617309575/7182027612';

  static String get bannerId =>
      kReleaseMode ? _productionBannerId : _testBannerId;

  static String get interstitialId =>
      kReleaseMode ? _productionInterstitialId : _testInterstitialId;
}
