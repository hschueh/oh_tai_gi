// Google Play flavor. `scripts/make_foss.sh` replaces this file with
// `ads_foss.dart` for the F-Droid build.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oh_tai_gi/utils/secret.dart';

class Ads {
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization failed: $e');
    }
  }

  static String? get _bannerAdUnitId {
    if (Platform.isAndroid) return BannerAdUnitId['Android'];
    if (Platform.isIOS) return BannerAdUnitId['iOS'];
    return null;
  }
}

/// A 320x50 banner, or nothing when the ad cannot be loaded.
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final adUnitId = Ads._bannerAdUnitId;
    if (adUnitId == null) return;
    _ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
