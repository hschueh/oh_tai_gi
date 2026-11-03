// Google Play flavor. `scripts/make_foss.sh` replaces this file with
// `telemetry_foss.dart` for the F-Droid build.
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Firebase Analytics and Crashlytics.
class Telemetry {
  static final List<NavigatorObserver> navigatorObservers = [];

  static Future<void> initialize() async {
    try {
      // Reads google-services.json / GoogleService-Info.plist.
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      return;
    }

    final crashlytics = FirebaseCrashlytics.instance;
    // Only collect crashes from release builds.
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    navigatorObservers
        .add(FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance));
  }
}
