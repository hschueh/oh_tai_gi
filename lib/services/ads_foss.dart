// F-Droid flavor: no ads. `scripts/make_foss.sh` copies this over `ads.dart`.
import 'package:flutter/widgets.dart';

class Ads {
  static Future<void> initialize() async {}
}

class BannerAdView extends StatelessWidget {
  const BannerAdView({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
