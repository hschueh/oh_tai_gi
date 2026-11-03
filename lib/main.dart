import 'dart:async';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/services/ads.dart';
import 'package:oh_tai_gi/services/telemetry.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/configuration_page.dart';
import 'package:oh_tai_gi/ui/page/flip_game_page.dart';
import 'package:oh_tai_gi/ui/page/list_page.dart';
import 'package:oh_tai_gi/ui/page/search_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/ui/page/unused_page.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';

const List<Destination> allDestinations = <Destination>[
  Destination(0, '凊彩學學', Icons.shuffle, Colors.teal),
  Destination(1, '主題詞彙', Icons.list, Colors.cyan),
  Destination(2, '𨑨迌溫習', Icons.videogame_asset, Colors.orange),
  Destination(3, '學習歷程', Icons.repeat, Colors.blue),
  Destination(4, '揣詞', Icons.search, Colors.green),
  Destination(5, '設定', Icons.settings, Colors.grey),
];

const int _flipGameIndex = 2;
const int _historyIndex = 3;
const int _searchIndex = 4;

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showAds = true});

  /// Disabled in widget tests.
  final bool showAds;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final List<AnimationController> _faders;
  late final AnimationController _hide;
  late final List<Key> _destinationKeys;
  late final List<Widget> _destinationPages;
  int _currentIndex = 0;

  final GlobalKey<SmallCardListPageState> _keySmallCardPage = GlobalKey();
  final GlobalKey<FlipGamePageState> _keyFlipCardPage = GlobalKey();
  final GlobalKey<ListRoutePageState> _keyListPage = GlobalKey();
  final GlobalKey<SearchPageState> _keySearchPage = GlobalKey();

  @override
  void initState() {
    super.initState();

    _faders = allDestinations
        .map((_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 200)))
        .toList();
    _faders[_currentIndex].value = 1.0;
    _hide = AnimationController(vsync: this, duration: kThemeAnimationDuration)
      ..value = 1.0;
    _destinationKeys =
        List<Key>.generate(allDestinations.length, (_) => GlobalKey());
    _destinationPages = [
      for (final destination in allDestinations) _buildPage(destination),
    ];

    isSearchKeywordEmpty().then((isEmpty) {
      if (!isEmpty) _select(_searchIndex);
    });
    listenSearchKeyword((keyword) {
      _select(_searchIndex);
      _keySearchPage.currentState?.search(keyword);
    });
  }

  Widget _buildPage(Destination destination) {
    switch (destination.index) {
      case 0:
        return BigCardPage(destination: destination);
      case 1:
        return ListRoutePage(
          key: _keyListPage,
          forward: () => _hide.forward(),
          reverse: () => _hide.reverse(),
          destination: destination,
        );
      case _flipGameIndex:
        return FlipGamePage(key: _keyFlipCardPage, destination: destination);
      case _historyIndex:
        return SmallCardListPage(
            key: _keySmallCardPage, destination: destination);
      case _searchIndex:
        return SearchPage(key: _keySearchPage, destination: destination);
      case 5:
        return ConfigurationPage(destination: destination);
      default:
        return UnfinishedPage(destination: destination);
    }
  }

  /// Switches to tab [index] and reloads the pages that show learning
  /// progress, which may have changed in the other tabs.
  void _select(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
    if (index == _historyIndex) {
      _keySmallCardPage.currentState?.refresh();
    } else if (index == _flipGameIndex) {
      _keyFlipCardPage.currentState?.refresh();
    }
  }

  @override
  void dispose() {
    for (final controller in _faders) {
      controller.dispose();
    }
    _hide.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0 && notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          _hide.forward();
        case ScrollDirection.reverse:
          _hide.reverse();
        case ScrollDirection.idle:
          break;
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
            children: allDestinations.map((destination) {
              final Widget view = FadeTransition(
                opacity: _faders[destination.index]
                    .drive(CurveTween(curve: Curves.fastOutSlowIn)),
                child: KeyedSubtree(
                  key: _destinationKeys[destination.index],
                  child: _destinationPages[destination.index],
                ),
              );
              if (destination.index == _currentIndex) {
                _faders[destination.index].forward();
                return view;
              }
              _faders[destination.index].reverse();
              if (_faders[destination.index].isAnimating) {
                return IgnorePointer(child: view);
              }
              return Offstage(child: view);
            }).toList(),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showAds) const BannerAdView(),
            ClipRect(
              child: SizeTransition(
                sizeFactor: _hide,
                alignment: Alignment.topCenter,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  currentIndex: _currentIndex,
                  onTap: _select,
                  items: [
                    for (final destination in allDestinations)
                      BottomNavigationBarItem(
                        icon: Icon(destination.icon),
                        backgroundColor: destination.color,
                        label: destination.title,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OhTaiGiApp extends StatelessWidget {
  const OhTaiGiApp({super.key, this.showAds = true});

  final bool showAds;

  @override
  Widget build(BuildContext context) {
    return FeatureDiscovery(
      child: MaterialApp(
        title: '熊愛學臺語',
        theme: ThemeData(
          // Keep the original Material 2 look for now.
          useMaterial3: false,
          fontFamily: 'huninn',
        ),
        debugShowCheckedModeBanner: false,
        home: HomePage(showAds: showAds),
        navigatorObservers: Telemetry.navigatorObservers,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Telemetry.initialize();
  unawaited(Ads.initialize());
  await OTGConfig.initialize();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const OhTaiGiApp());
}
