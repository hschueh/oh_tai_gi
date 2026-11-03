import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_list_card.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/utils/utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// The "主題詞彙" tab: a nested navigator with the vocabulary lists (`/`), the
/// words of one list (`/list`) and the flash cards of one list (`/learn`).
class ListRoutePage extends StatefulWidget {
  const ListRoutePage(
      {super.key, required this.destination, this.forward, this.reverse});

  final Destination destination;
  final VoidCallback? forward;
  final VoidCallback? reverse;

  @override
  ListRoutePageState createState() => ListRoutePageState();
}

class ListRoutePageState extends State<ListRoutePage> {
  VocabularyList? vocabularyList;
  bool isList = true;
  YoutubePlayerController? _controller;

  void _setVocabularyList(BuildContext context, VocabularyList list) {
    vocabularyList = list;
    Navigator.of(context).pushNamed('/list');
    isList = true;
  }

  void _setController(YoutubePlayerController? controller) =>
      _controller = controller;

  void pauseVideo() => _controller?.pauseVideo();

  void _toggleMode(BuildContext context) {
    if (isList) {
      Navigator.of(context).popAndPushNamed('/learn');
    } else {
      Navigator.of(context).popAndPushNamed('/list');
    }
    isList = !isList;
  }

  @override
  Widget build(BuildContext context) {
    return ListDataHolder(
      vocabularyList: vocabularyList,
      setVocabularyList: _setVocabularyList,
      child: Navigator(
        observers: [
          ViewNavigatorObserver(widget.forward, widget.reverse, pauseVideo),
        ],
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              final list = vocabularyList;
              switch (settings.name) {
                case '/list' when list != null:
                  return SmallCardListPage(
                    destination: widget.destination,
                    vocabularyList: list,
                    switchToLearning: _toggleMode,
                    setController: _setController,
                  );
                case '/learn' when list != null:
                  return BigCardPage(
                    destination: widget.destination,
                    vocabularyList: list,
                    switchToList: _toggleMode,
                  );
                default:
                  return VocabularyListPage(destination: widget.destination);
              }
            },
          );
        },
      ),
    );
  }
}

class ViewNavigatorObserver extends NavigatorObserver {
  ViewNavigatorObserver(this._forward, this._reverse, this._pause);

  final VoidCallback? _forward;
  final VoidCallback? _reverse;
  final VoidCallback _pause;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == '/list') _pause();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Hide the bottom navigation bar while browsing a list.
    if (route.settings.name == '/list') {
      _reverse?.call();
    } else {
      _forward?.call();
    }
  }
}

class ListDataHolder extends InheritedWidget {
  const ListDataHolder(
      {super.key,
      this.vocabularyList,
      required this.setVocabularyList,
      required super.child});

  final VocabularyList? vocabularyList;
  final OnVocabularyListTap setVocabularyList;

  static ListDataHolder of(BuildContext context) {
    final holder =
        context.dependOnInheritedWidgetOfExactType<ListDataHolder>();
    assert(holder != null, 'No ListDataHolder found in context');
    return holder!;
  }

  @override
  bool updateShouldNotify(ListDataHolder oldWidget) =>
      oldWidget.vocabularyList != vocabularyList;
}

class VocabularyListPage extends StatefulWidget {
  const VocabularyListPage({super.key, required this.destination});

  final Destination destination;

  @override
  VocabularyListPageState createState() => VocabularyListPageState();
}

class VocabularyListPageState extends State<VocabularyListPage> {
  final List<VocabularyList> _vocabularyLists = [];
  final VocabularyListProvider vlp = VocabularyListProvider();
  int _newCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    _vocabularyLists.clear();
    retrieveVocabularyList();
  }

  Future<void> retrieveVocabularyList() async {
    await vlp.open();

    var vs = await vlp.getVocabularyLists();
    final listsFromServer = await vlp.fetchVocabularyLists(skip: vs.length);
    var listsToInsert =
        listsFromServer.where((list) => !vs.contains(list)).toList();
    listsToInsert = await vlp.insertAll(listsToInsert);
    vs.insertAll(0, listsToInsert);
    // Backup plan: the lists bundled with the app.
    if (vs.isEmpty) {
      final contents = await getFileData('assets/dict/dict-list.json');
      vs = (json.decode(contents) as List)
          .map<VocabularyList>(
              (item) => VocabularyList.fromJson(item as Map<String, dynamic>))
          .toList();
      vs = await vlp.insertAll(vs);
    }
    if (!mounted) return;
    setState(() {
      _vocabularyLists.addAll(vs);
      _newCount = listsToInsert.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_vocabularyLists.isNotEmpty) {
      body = ListView.builder(
        itemCount: _vocabularyLists.length,
        itemBuilder: (context, position) {
          return SmallVocabularyListCard(
            _vocabularyLists[position],
            _newCount > position,
            ListDataHolder.of(context).setVocabularyList,
          );
        },
      );
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/launcher/icon_tired.png'),
            Text('資料庫中沒有單字表',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
    );
  }
}
