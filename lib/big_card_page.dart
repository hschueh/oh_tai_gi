import 'dart:convert';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";
  _BigCardPageState() {
    if(IS_DEBUG) {
      AudioPlayer.logEnabled = true;
    }
    initialize();
  }


  void initialize() async {
    String contents = await getFileData("assets/dict/dict-twblg-ext.json");
    List<Vocabulary> vs = json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList();
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
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
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
    List<Widget> children = <Widget>[
    ];
    String title = "讀取中...";
    if(_index < vocabularies.length) {
      Vocabulary v = vocabularies[_index];
      title = v.title;
      for(int i = 0; i < v.heteronyms.length; ++i) {
        children.add(Text(
          "${i+1}: ${v.heteronyms[i].trs}" ,
          style: Theme.of(context).textTheme.display1,
        ));
        for(int j = 0; j < v.heteronyms[i].definitions.length; ++j) {
          children.add(Text(
            "${v.heteronyms[i].definitions[j].def}" ,
            style: Theme.of(context).textTheme.display1,
          ));
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Center(
        widthFactor: 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.display2,
            ),
            Expanded(
              child: ListView(
                children: children,
              )
            ),
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _next,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
