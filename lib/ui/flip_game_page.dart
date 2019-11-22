import 'dart:math';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/flippable_card.dart';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';

class FlipGamePage extends StatefulWidget {
  FlipGamePage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  FlipGamePageState createState() => FlipGamePageState();
}

class FlipGamePageState extends State<FlipGamePage> {
  List<Vocabulary> vocabularies = [];
  List<int> shuffler = List<int>.generate(12, (i) => i);
  int correctCnt = 0;
  List<GlobalKey<FlipCardState>> keys = List<GlobalKey<FlipCardState>>.generate(12, (i) => GlobalKey<FlipCardState>());
  VocabularyProvider vp;
  GlobalKey<FlipCardState> flippedKey;
  Vocabulary flippedVocabulary;
  FlipGamePageState();

  onFlip(GlobalKey<FlipCardState> key, Vocabulary vocabulary) {
    if(flippedKey == null) {
      flippedKey = key;
      flippedVocabulary = vocabulary;
      return;
    }

    if(vocabulary.id != flippedVocabulary.id) {
      flippedKey.currentState.toggleCard();
      key.currentState.toggleCard();
    } else {
      ++correctCnt;
      if(correctCnt == 6) {
        correctCnt = 0;
        AudioPlayerHolder.playLocal("win.wav");
        refresh();
        keys.forEach((key) => key.currentState.toggleCard());
      } else {
        AudioPlayerHolder.playLocal("correct.wav");
      }
    }
    flippedKey = null;
    flippedVocabulary = null;
  }

  refresh() {
    retrieveVocabularyList();
    shuffler.shuffle();
  }

  void retrieveVocabularyList() async {
    if(vp == null) {
      vp = VocabularyProvider();
      await vp.open('vocabulary.db');
    }
    List<Vocabulary> vs = await vp.getVocabularyList(where: '$columnLearnt > ?', whereArgs: ["0"]);
    if(vs.length > 0) {
      _setVocabularyList(vs);
      return;
    }
  }

  void _setVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies = vs;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(vocabularies.length >= 6) {
      body = GridView.builder(
        itemCount: 12,
        itemBuilder: (context, position) {
          int realPos = shuffler[position];
          return FlippableCard(vocabularies[(realPos/2).floor()], realPos%2 == 0, onFlip, keys[realPos], key: UniqueKey());
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mood_bad),
            Text("你還沒有學過的單詞！", style: Theme.of(context).textTheme.body1,)
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
