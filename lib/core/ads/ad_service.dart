import 'dart:async';

import 'package:cricket_scorer_pro/core/ads/ad_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AdService {
  static Future<bool>? _initialization;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> initialize() {
    if (!isSupported) return Future.value(false);
    return _initialization ??= _initializeSafely();
  }

  static Future<bool> _initializeSafely() async {
    try {
      await MobileAds.instance.initialize();
      return true;
    } catch (error, stackTrace) {
      debugPrint('AdMob initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<BannerAd?> loadAdaptiveBanner({
    required int width,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (width <= 0 || !await initialize()) return null;

    BannerAd? banner;
    Timer? timer;
    final result = Completer<BannerAd?>();

    void complete(BannerAd? value) {
      if (result.isCompleted) {
        value?.dispose();
        return;
      }
      timer?.cancel();
      result.complete(value);
    }

    try {
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (size == null) return null;

      banner = BannerAd(
        adUnitId: AdConfig.bannerId,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (ad) => complete(ad as BannerAd),
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: $error');
            ad.dispose();
            complete(null);
          },
        ),
      );
      timer = Timer(timeout, () {
        banner?.dispose();
        complete(null);
      });
      await banner.load();
      return result.future;
    } catch (error, stackTrace) {
      timer?.cancel();
      banner?.dispose();
      debugPrint('Banner setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      complete(null);
      return result.future;
    }
  }

  static Future<bool> showExportInterstitialOnce(String matchId) async {
    final preferences = await SharedPreferences.getInstance();
    final shownKey = 'export_interstitial_$matchId';
    if (preferences.getBool(shownKey) ?? false) return false;
    if (!await initialize()) return false;

    final loaded = Completer<InterstitialAd?>();
    Timer? timer;
    InterstitialAd? pendingAd;

    void completeLoad(InterstitialAd? ad) {
      if (loaded.isCompleted) {
        ad?.dispose();
        return;
      }
      timer?.cancel();
      loaded.complete(ad);
    }

    try {
      timer = Timer(const Duration(seconds: 5), () {
        pendingAd?.dispose();
        completeLoad(null);
      });
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            pendingAd = ad;
            completeLoad(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed to load: $error');
            completeLoad(null);
          },
        ),
      );
      final ad = await loaded.future;
      if (ad == null) return false;

      final closed = Completer<void>();
      void finish() {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      }

      ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
        onAdDismissedFullScreenContent: (_) => finish(),
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('Interstitial failed to show: $error');
          finish();
        },
      );
      await preferences.setBool(shownKey, true);
      await ad.show();
      await closed.future.timeout(
        const Duration(seconds: 45),
        onTimeout: finish,
      );
      return true;
    } catch (error, stackTrace) {
      timer?.cancel();
      pendingAd?.dispose();
      debugPrint('Interstitial setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
