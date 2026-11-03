// F-Droid flavor: no tracking. `scripts/make_foss.sh` copies this over
// `telemetry.dart`.
import 'package:flutter/widgets.dart';

class Telemetry {
  static final List<NavigatorObserver> navigatorObservers = [];

  static Future<void> initialize() async {}
}
