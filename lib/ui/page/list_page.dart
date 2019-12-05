import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart';
import 'package:oh_tai_gi/ui/page/small_card_page.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_list_card.dart';
import 'package:oh_tai_gi/utils/utils.dart';

const bool IS_DEBUG = false;

class ListRoutePage extends StatefulWidget {
  const ListRoutePage({ Key key, this.destination, this.onNavigation }) : super(key: key);

  final Destination destination;
  final VoidCallback onNavigation;

  @override
  _ListRoutePageState createState() => _ListRoutePageState();
}

class _ListRoutePageState extends State<ListRoutePage> {
  List<String> vocabularyTitles;
  bool isList = true;
  void _setVocabularyTitles(BuildContext _context, List<String> list) {
    vocabularyTitles = list;
    Navigator.pushNamed(_context, "/list");
    isList = true;
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
        vocabularyTitles: vocabularyTitles,
        setVocabularyTitles: _setVocabularyTitles,
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
                  return SmallCardListPage(destination: widget.destination, vocabularyList: vocabularyTitles, switchToLearning: _toggleMode,);
                case '/learn':
                  return BigCardPage(destination: widget.destination, vocabularyList: vocabularyTitles, switchToList: _toggleMode,);
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
  ListDataHolder({ this.vocabularyTitles, this.setVocabularyTitles, Widget child }) :super(child: child);

  final List<String> vocabularyTitles;
  final Function setVocabularyTitles;

  static ListDataHolder of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(ListDataHolder);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return (oldWidget as ListDataHolder).vocabularyTitles.toString() != vocabularyTitles.toString();
  }
}

class VocabularyListPage extends StatefulWidget {
  VocabularyListPage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  VocabularyListPageState createState() => VocabularyListPageState();
}

class VocabularyListPageState extends State<VocabularyListPage> {
  List<VocabularyList> vocabularyLists = [];
  VocabularyListProvider vlp;
  VocabularyListPageState() {
    refresh();
  }

  refresh() {
    this.vocabularyLists.clear();
    retrieveVocabularyList();
  }

  void retrieveVocabularyList() async {
    if(vlp == null) {
      vlp = VocabularyListProvider();
      await vlp.open();
    }
    List<VocabularyList> vs = await vlp.getVocabularyLists();
    if(vs.length == 0) {
      vs.insertAll(0, await vlp.fetchVocabularyLists());
      vs = await vlp.insertAll(vs);
    }
    if(vs.length == 0) {
      String contents = await getFileData("assets/dict/dict-list.json");
      vs.insertAll(0, json.decode(contents).map<VocabularyList>((json) => VocabularyList.fromJson(json)).toList());
      vs = await vlp.insertAll(vs);
    }
    _appendVocabularyList(vs);
  }

  void _appendVocabularyList(List<VocabularyList> vs) {
    setState(() {
      this.vocabularyLists.addAll(vs);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(vocabularyLists.length > 0) {
      body = ListView.builder(
        itemCount: vocabularyLists.length,
        itemBuilder: (context, position) {
          return SmallVocabularyListCard(
            vocabularyLists[position],
            ListDataHolder.of(context).setVocabularyTitles,
            key: UniqueKey());
        },
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mood_bad),
            Text("資料庫中沒有單字表", style: Theme.of(context).textTheme.body1,)
          ],
        )
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _next(true),
      //   tooltip: 'Increment',
      //   child: Icon(Icons.thumb_up),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
