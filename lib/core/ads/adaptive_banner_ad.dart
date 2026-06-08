import 'dart:async';

import 'package:cricket_scorer_pro/core/ads/ad_config.dart';
import 'package:cricket_scorer_pro/core/ads/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdaptiveBannerAd extends StatefulWidget {
  const AdaptiveBannerAd({this.maxWidth, super.key});

  final double? maxWidth;

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _banner;
  int? _loadedWidth;
  int _loadGeneration = 0;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AdService.isSupported) return;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width =
        (widget.maxWidth == null
                ? screenWidth
                : screenWidth.clamp(0, widget.maxWidth!))
            .truncate();
    if (width > 0 && width != _loadedWidth) {
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    _retryTimer?.cancel();
    _loadedWidth = width;
    final generation = ++_loadGeneration;
    try {
      final initialized = await AdService.initialize();
      if (!initialized || !mounted || generation != _loadGeneration) return;
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || size == null || generation != _loadGeneration) return;
      final previous = _banner;
      final banner = BannerAd(
        adUnitId: AdConfig.bannerId,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || generation != _loadGeneration) {
              ad.dispose();
              return;
            }
            previous?.dispose();
            setState(() => _banner = ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: $error');
            ad.dispose();
            if (mounted && generation == _loadGeneration) {
              setState(() => _banner = null);
              _scheduleRetry(width);
            }
          },
        ),
      );
      banner.load();
    } catch (error, stackTrace) {
      debugPrint('Banner setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted && generation == _loadGeneration) {
        setState(() => _banner = null);
        _scheduleRetry(width);
      }
    }
  }

  void _scheduleRetry(int width) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) _load(width);
    });
  }

  @override
  void dispose() {
    _loadGeneration++;
    _retryTimer?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Center(
          child: SizedBox(
            width: banner.size.width.toDouble(),
            height: banner.size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
