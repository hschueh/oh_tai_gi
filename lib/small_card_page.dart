import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/small_card.dart';

import 'db/vocabulary.dart';
import 'destination.dart';
import 'package:oh_tai_gi/utils/utils.dart';

const bool IS_DEBUG = false;

class SmallCardListPage extends StatefulWidget {
  SmallCardListPage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  _SmallCardListPageState createState() => _SmallCardListPageState();
}

class _SmallCardListPageState extends State<SmallCardListPage> {
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  _SmallCardListPageState() {
    if(IS_DEBUG) {
      AudioPlayer.logEnabled = true;
    }
    initialize();
  }

  void initialize() async {
    vp = VocabularyProvider();
    await vp.open('vocabulary.db');
    List<Vocabulary> vs = await vp.getVocabularyList();
    if(vs.length > 0) {
      _setVocabularyList(vs);
      return;
    }
    String contents = await getFileData("assets/dict/dict-twblg-ext.json");
    vs = json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList();
    await vp.insertAll(vs);
    _setVocabularyList(vs);
  }

  void _setVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies = vs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: ListView.builder(
        itemCount: vocabularies.length,
        itemBuilder: (context, position) {
          return SmallCard(vocabularies[position], key: UniqueKey());
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _next(true),
      //   tooltip: 'Increment',
      //   child: Icon(Icons.thumb_up),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
