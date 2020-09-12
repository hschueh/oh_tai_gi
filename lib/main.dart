import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:oh_tai_gi/ui/page/search_page.dart';

import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';
import 'destination.dart';

const USE_FIREBASE_ADMOB = false;

const List<Destination> allDestinations = <Destination>[
  Destination(0, '揣詞', Icons.search, Colors.cyan),
];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  AnimationController _hide;
  Widget bannerAds = SizedBox(width: 0, height: 0,);

  @override
  void initState() {
    super.initState();

    if(USE_FIREBASE_ADMOB) {
      BannerAd banner = BannerAd(
        adUnitId: getBannerAdUnitId(),
        size: AdSize.smartBanner,
        listener: (MobileAdEvent event) {
          print("BannerAd event is $event");
        },
      );
      getBannerHeight().then((height) {
        banner..load()
        ..show(
          anchorOffset: height,
          anchorType: AnchorType.top,
        );
      });
    } else {
      bannerAds = AdmobBanner(
        adUnitId: getBannerAdUnitId(),
        adSize: AdmobBannerSize.BANNER,
        onBannerCreated: (controller) {
          print(controller);
        },
      );
    }
  }

  @override
  void dispose() {
    _hide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          top: false,
          child: SearchPage(key: UniqueKey(), destination: allDestinations[0])
        ),
        bottomNavigationBar:bannerAds,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FirebaseAnalytics analytics = FirebaseAnalytics();
  // Usually could be disable unless we want to check if the crashlytics accually works.
  Crashlytics.instance.enableInDevMode = false;
  
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  if(USE_FIREBASE_ADMOB) {
    FirebaseAdMob.instance.initialize(appId: getAdAppId());
  } else {
    Admob.initialize(getAdAppId());
  }
  OTGConfig.initialize().then((_)async{
    await SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        runApp(
          FeatureDiscovery(
            child: MaterialApp(
              theme: ThemeData(
                fontFamily: 'huninn',
              ),
              debugShowCheckedModeBanner: false,
              home: HomePage(),
              navigatorObservers: [
                FirebaseAnalyticsObserver(analytics: analytics),
              ],
            )
          )
        );
      });
    }
  );
}