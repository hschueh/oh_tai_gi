import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/big_card.dart';

import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/utils/utils.dart';

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
  _BigCardPageState() {
    initialize();
  }

  void initialize() async {
    vp = VocabularyProvider();
    await vp.open('vocabulary.db');
    List<Vocabulary> vs = await vp.getVocabularyList();
    if(vs.length > 0) {
      _appendVocabularyList(vs);
      return;
    }
    String contents = await getFileData("assets/dict/dict-twblg-ext.json");
    vs = json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList();
    vs = await vp.insertAll(vs);
    _appendVocabularyList(vs);
  }

  void _tryToPlayAudio() async {
    if(_index >= vocabularies.length)
      return;
    int connectivity = await getConnectivityResult();
    int autoPlaySetting = OTGConfig.of(context).get(OTGConfig.keyAutoPlayAudio, 0);
    if(autoPlaySetting > connectivity)
      return;
    Vocabulary v = vocabularies[_index];
    for(int i = 0; i < v.heteronyms.length; ++i) {
      await AudioPlayerHolder.tryToPlayAudio(v.heteronyms[i].aid);
    }
  }

  void _next(bool thumbUp) {
    Vocabulary v = vocabularies[_index];
    v.learnt = v.learnt+1;
    vp.update(v).then(
      (result) => print("Update result: $result")
    );
    setState(() {
      _index++;
      _tryToPlayAudio();
    });
  }

  void _appendVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies.addAll(vs);
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
    // final controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
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
        child: Dismissible(
          background: Card(
            color: Colors.green,
            child:Container(
              padding: const EdgeInsets.only(left: 15),
              alignment: Alignment.centerLeft,
              child:Icon(Icons.mood, size: 64,)
            )
          ),
          secondaryBackground: Card(
            color: Colors.yellow,
            child:Container(
              padding: const EdgeInsets.only(right: 15),
              alignment: Alignment.centerRight,child:Icon(Icons.mood_bad, size: 64,)
            )
          ),
          onDismissed: (DismissDirection direction){
            if(direction == DismissDirection.startToEnd) {
              _next(true);
            } else if(direction == DismissDirection.endToStart) {
              _next(false);
            }
          },
          child:BigCard(v),
          key: UniqueKey(),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _next(true),
      //   tooltip: 'Increment',
      //   child: Icon(Icons.thumb_up),
      // ),
    );
  }
}
