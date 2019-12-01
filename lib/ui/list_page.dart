import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/small_vocabulary_list_card.dart';
import 'package:oh_tai_gi/utils/utils.dart';

const bool IS_DEBUG = false;

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
          return SmallVocabularyListCard(vocabularyLists[position], key: UniqueKey());
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
