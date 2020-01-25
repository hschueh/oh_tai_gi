import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_list_card.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const bool IS_DEBUG = false;

class ListRoutePage extends StatefulWidget {
  const ListRoutePage({ Key key, this.destination, this.onNavigation }) : super(key: key);

  final Destination destination;
  final VoidCallback onNavigation;

  @override
  ListRoutePageState createState() => ListRoutePageState();
}

class ListRoutePageState extends State<ListRoutePage> {
  VocabularyList vocabularyList;
  bool isList = true;
  YoutubePlayerController _controller;
  void _setVocabularyList(BuildContext _context, VocabularyList list) {
    vocabularyList = list;
    Navigator.pushNamed(_context, "/list");
    isList = true;
  }

  void _setController(YoutubePlayerController controller) => _controller = controller;

  pauseVideo() {
    if(_controller != null) _controller.pause();
  }

  void _toggleMode(BuildContext _context) {
    if(isList)
      Navigator.popAndPushNamed(_context, "/learn");
    else
      Navigator.popAndPushNamed(_context, "/list");
    
    isList = !isList;
  }

  @override
  Widget build(BuildContext context) {
    return ListDataHolder(
        vocabularyList: vocabularyList,
        setVocabularyList: _setVocabularyList,
        child: Navigator(
        observers: <NavigatorObserver>[
          ViewNavigatorObserver(widget.onNavigation),
        ],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              switch(settings.name) {
                case '/list':
                  return SmallCardListPage(
                    destination: widget.destination,
                    vocabularyList: vocabularyList,
                    switchToLearning: _toggleMode,
                    setController: _setController
                    );
                case '/learn':
                  return BigCardPage(destination: widget.destination, vocabularyList: vocabularyList, switchToList: _toggleMode,);
                case '/':
                default:
                  return VocabularyListPage(destination: widget.destination);
              }
            },
          );
        },
      )
    );
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

class ListDataHolder extends InheritedWidget {
  ListDataHolder({ this.vocabularyList, this.setVocabularyList, Widget child }) :super(child: child);

  final VocabularyList vocabularyList;
  final Function setVocabularyList;

  static ListDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ListDataHolder>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return (oldWidget as ListDataHolder).vocabularyList.toString() != vocabularyList.toString();
  }
}

class VocabularyListPage extends StatefulWidget {
  VocabularyListPage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  VocabularyListPageState createState() => VocabularyListPageState();
}

class VocabularyListPageState extends State<VocabularyListPage> {
  List<VocabularyList> _vocabularyLists = [];
  VocabularyListProvider vlp;
  int _newCount = 0;
  VocabularyListPageState() {
    refresh();
  }

  refresh() {
    this._vocabularyLists.clear();
    retrieveVocabularyList();
  }

  void retrieveVocabularyList() async {
    if(vlp == null) {
      vlp = VocabularyListProvider();
      await vlp.open();
    }

    List<VocabularyList> vs = await vlp.getVocabularyLists();
    List<VocabularyList> listsFromServer = await vlp.fetchVocabularyLists(skip: vs.length);
    List<VocabularyList> listsToInsert = [];
    listsFromServer.forEach((list){
      if(!vs.contains(list))
        listsToInsert.add(list);
    });
    listsToInsert = await vlp.insertAll(listsToInsert);
    vs.insertAll(0, listsToInsert);
    //backup plan
    if(vs.length == 0) {
      String contents = await getFileData("assets/dict/dict-list.json");
      vs.insertAll(0, json.decode(contents).map<VocabularyList>((json) => VocabularyList.fromJson(json)).toList());
      vs = await vlp.insertAll(vs);
    }
    _appendVocabularyList(vs, listsToInsert.length);
  }

  void _appendVocabularyList(List<VocabularyList> vs, int newCount) {
    setState(() {
      this._vocabularyLists.addAll(vs);
      this._newCount = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(_vocabularyLists.length > 0) {
      body = ListView.builder(
        itemCount: _vocabularyLists.length,
        itemBuilder: (context, position) {
          return new SmallVocabularyListCard(
            _vocabularyLists[position],
            _newCount > position,
            ListDataHolder.of(context).setVocabularyList,
            key: UniqueKey(),
          );
        },
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/launcher/icon_tired.png"),
            Text("資料庫中沒有單字表", style: Theme.of(context).textTheme.body1,)
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
