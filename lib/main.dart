import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/flip_game_page.dart';
import 'package:oh_tai_gi/ui/page/list_page.dart';
import 'package:oh_tai_gi/ui/page/search_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/ui/page/configuration_page.dart';
import 'package:oh_tai_gi/ui/page/unused_page.dart';

import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';
import 'destination.dart';

const USE_FIREBASE_ADMOB = false;

const List<Destination> allDestinations = <Destination>[
  Destination(0, '凊彩學學', Icons.shuffle, Colors.teal),
  Destination(1, '主題詞彙', Icons.list, Colors.cyan),
  Destination(2, '𨑨迌溫習', Icons.videogame_asset, Colors.orange),
  Destination(3, '學習歷程', Icons.repeat, Colors.blue),
  Destination(4, '揣詞', Icons.search, Colors.green),
  Destination(5, '設定', Icons.settings, Colors.grey)
];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  List<Key> _destinationKeys;
  List<Widget> _destinationPages;
  List<AnimationController> _faders;
  AnimationController _hide;
  int _currentIndex = 0;
  Widget bannerAds = SizedBox(width: 0, height: 0,);

  final GlobalKey<SmallCardListPageState> _keySmallCardPage = GlobalKey();
  final GlobalKey<FlipGamePageState> _keyFlipCardPage = GlobalKey();
  final GlobalKey<ListRoutePageState> _keyListPage = GlobalKey();
  

  @override
  void initState() {
    super.initState();

    _faders = allDestinations.map<AnimationController>((Destination destination) {
      return AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    }).toList();
    _faders[_currentIndex].value = 1.0;
    _destinationKeys = List<Key>.generate(allDestinations.length, (int index) => GlobalKey()).toList();
    _destinationPages = List<Widget>.generate(
      allDestinations.length,
      (int index) {
        switch (index) {
          case 0:
            return BigCardPage(key: UniqueKey(), destination: allDestinations[index]);
            break;
          case 1:
            return ListRoutePage(key: _keyListPage, onNavigation: () => _hide.forward(),destination: allDestinations[index]);
            break;
          case 2:
            return FlipGamePage(key: _keyFlipCardPage, destination: allDestinations[index]);
            break;
          case 3:
            return SmallCardListPage(key: _keySmallCardPage, destination: allDestinations[index]);
            break;
          case 4:
            return SearchPage(key: UniqueKey(), destination: allDestinations[index]);
            break;
          case 5:
            return ConfigurationPage(key: UniqueKey(), destination: allDestinations[index]);
            break;
          default:
            return UnfinishedPage(key: UniqueKey(), destination: allDestinations[index]);
        }
      }).toList();
    _hide = AnimationController(vsync: this, duration: kThemeAnimationDuration);

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

    isSearchKeywordEmpty().then((isEmpty)=>{
      if(!isEmpty) {
        setState(() {
          _currentIndex = 4;
        })
      }
    });
  }

  @override
  void dispose() {
    for (AnimationController controller in _faders)
      controller.dispose();
    _hide.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is UserScrollNotification) {
        final UserScrollNotification userScroll = notification;
        switch (userScroll.direction) {
          case ScrollDirection.forward:
            _hide.forward();
            break;
          case ScrollDirection.reverse:
            _hide.reverse();
            break;
          case ScrollDirection.idle:
            break;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: allDestinations.map((Destination destination) {
              final Widget view = FadeTransition(
                opacity: _faders[destination.index].drive(CurveTween(curve: Curves.fastOutSlowIn)),
                child: KeyedSubtree(
                  key: _destinationKeys[destination.index],
                  child: _destinationPages[destination.index],
                ),
              );
              if (destination.index == _currentIndex) {
                _faders[destination.index].forward();
                if(_currentIndex == 3) {
                  _keySmallCardPage.currentState.refresh();
                } else if (_currentIndex == 2) {
                  _keyFlipCardPage.currentState.refresh();
                }
                // TODO Does big card page need to refresh?
                return view;
              } else {
                _faders[destination.index].reverse();
                if (_faders[destination.index].isAnimating) {
                  return IgnorePointer(child: view);
                }
                return Offstage(child: view);
              }
            }).toList(),
          ),
        ),
        bottomNavigationBar:
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children:[
              bannerAds,
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _hide,
                  axisAlignment: -1.0,
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (int index) {
                      setState(() {
                        if(_currentIndex == 1) {
                          _keyListPage.currentState.pauseVideo();
                        }
                        _currentIndex = index;
                      });
                    },
                    items: allDestinations.map((Destination destination) {
                      return BottomNavigationBarItem(
                        icon: Icon(destination.icon),
                        backgroundColor: destination.color,
                        title: Text(destination.title)
                      );
                    }).toList(),
                  ),
                ),
              ),
            ]
          ),
        ),
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
  OTGConfig.initialize().then((_) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        runApp(
          FeatureDiscovery(child:MaterialApp(
            debugShowCheckedModeBanner: false,
            home: HomePage(),
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: analytics),
            ],
          ))
        );
      });
    }
  );
}