import 'dart:convert';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/big_card.dart';

import 'db/vocabulary.dart';
import 'destination.dart';
import 'utils.dart';

const bool IS_DEBUG = false;

class BigCardPage extends StatefulWidget {
  BigCardPage({Key key, this.destination}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Destination destination;

  @override
  _BigCardPageState createState() => _BigCardPageState();
}

class _BigCardPageState extends State<BigCardPage> {
  int _index = 0;
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";
  _BigCardPageState() {
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

  void _tryToPlayAudio() async {
    if(_index >= vocabularies.length)
      return;
    Vocabulary v = vocabularies[_index];
    for(int i = 0; i < v.heteronyms.length; ++i) {
      String aid = v.heteronyms[i].aid.toString().padLeft(5, '0');
      int result = await audioPlayer.play("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
      if(IS_DEBUG) {
        print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
      }
    }
  }

  void _next() {
    setState(() {
      _index++;
      _tryToPlayAudio();
    });
  }

  void _setVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies = vs;
      _tryToPlayAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    Vocabulary v;
    if(_index < vocabularies.length) {
      v = vocabularies[_index];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: BigCard(v),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _next,
        tooltip: 'Increment',
        child: Icon(Icons.thumb_up),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
