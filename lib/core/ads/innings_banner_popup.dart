import 'package:cricket_scorer_pro/core/ads/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BannerPopupResult { shown, alreadyShown, unavailable }

abstract final class InningsBannerPopup {
  static final Set<String> _loading = <String>{};

  static Future<BannerPopupResult> showIfNeeded(
    BuildContext context, {
    required String matchId,
    required int innings,
    required String audience,
  }) async {
    final key = 'innings_banner_${audience}_${matchId}_$innings';
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(key) ?? false) {
      return BannerPopupResult.alreadyShown;
    }
    if (!_loading.add(key)) return BannerPopupResult.unavailable;
    if (!context.mounted) {
      _loading.remove(key);
      return BannerPopupResult.unavailable;
    }

    final width = (MediaQuery.sizeOf(context).width - 48)
        .clamp(280, 720)
        .truncate();
    final banner = await AdService.loadAdaptiveBanner(width: width);
    _loading.remove(key);
    if (!context.mounted || banner == null) {
      return BannerPopupResult.unavailable;
    }

    await preferences.setBool(key, true);
    if (!context.mounted) {
      banner.dispose();
      return BannerPopupResult.unavailable;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Theme.of(dialogContext).colorScheme.primaryContainer,
                padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
                child: Row(
                  children: [
                    const Icon(Icons.sports_cricket),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        innings == 1 ? 'First Innings' : 'Second Innings',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              ColoredBox(
                color: Theme.of(dialogContext).colorScheme.surface,
                child: SizedBox(
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  child: AdWidget(ad: banner),
                ),
              ),
            ],
          ),
        ),
      );
      return BannerPopupResult.shown;
    } finally {
      banner.dispose();
    }
  }
}
