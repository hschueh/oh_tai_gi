import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/flip_game_page.dart';
import 'package:oh_tai_gi/ui/page/list_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/ui/page/configuration_page.dart';

import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';
import 'destination.dart';

const USE_FIREBASE_ADMOB = false;

const List<Destination> allDestinations = <Destination>[
  Destination(0, '隨選隨學', Icons.shuffle, Colors.teal),
  Destination(1, '主題列表', Icons.list, Colors.cyan),
  Destination(2, '複習遊戲', Icons.videogame_asset, Colors.orange),
  Destination(3, '學習歷程', Icons.repeat, Colors.blue),
  Destination(4, '設置', Icons.settings, Colors.grey)
];


class UnfinishedPage extends StatelessWidget {
  const UnfinishedPage({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.title),
        backgroundColor: destination.color,
      ),
      backgroundColor: destination.color[50],
      body:Center(
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.announcement, size: 120,),
            Text("功能開發中...", style: Theme.of(context).textTheme.headline,)
          ],
        )
      ),
    );
  }
}


class RootPage extends StatelessWidget {
  const RootPage({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.title),
        backgroundColor: destination.color,
      ),
      backgroundColor: destination.color[50],
      body: SizedBox.expand(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, "/list");
          },
          child: Center(
            child: Text('tap here'),
          ),
        ),
      ),
    );
  }
}

class ListPage extends StatelessWidget {
  const ListPage({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    const List<int> shades = <int>[50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

    return Scaffold(
      appBar: AppBar(
        title: Text(destination.title),
        backgroundColor: destination.color,
      ),
      backgroundColor: destination.color[50],
      body: SizedBox.expand(
        child: ListView.builder(
          itemCount: shades.length,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(
              height: 128,
              child: Card(
                color: destination.color[shades[index]].withOpacity(0.25),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, "/text");
                  },
                  child: Center(
                    child: Text('Item $index', style: Theme.of(context).primaryTextTheme.display1),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TextPage extends StatefulWidget {
  const TextPage({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  _TextPageState createState() => _TextPageState();
}

class _TextPageState extends State<TextPage> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'sample text: ${widget.destination.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      backgroundColor: widget.destination.color[50],
      body: Container(
        padding: const EdgeInsets.all(32.0),
        alignment: Alignment.center,
        child: TextField(controller: _textController),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}


class ViewNavigatorObserver extends NavigatorObserver {
  ViewNavigatorObserver(this.onNavigation);

  final VoidCallback onNavigation;

  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    onNavigation();
  }
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    onNavigation();
  }
}

class DestinationView extends StatefulWidget {
  const DestinationView({ Key key, this.destination, this.onNavigation }) : super(key: key);

  final Destination destination;
  final VoidCallback onNavigation;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      observers: <NavigatorObserver>[
        ViewNavigatorObserver(widget.onNavigation),
      ],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            switch(settings.name) {
              case '/':
                return RootPage(destination: widget.destination);
              case '/list':
                return ListPage(destination: widget.destination);
              case '/text':
                return TextPage(destination: widget.destination);
              default:
                return UnfinishedPage(destination: widget.destination);
            }
          },
        );
      },
    );
  }
}

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
            return ListDataHolder(child:ListRoutePage(key: UniqueKey(), onNavigation: () => _hide.forward(),destination: allDestinations[index]));
            break;
          case 2:
            return FlipGamePage(key: _keyFlipCardPage, destination: allDestinations[index]);
            break;
          case 3:
            return SmallCardListPage(key: _keySmallCardPage, destination: allDestinations[index]);
            break;
          case 4:
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
      child: OTGConfig(child:Scaffold(
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
      )
    );
  }
}

void main() {
  FirebaseAnalytics analytics = FirebaseAnalytics();
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