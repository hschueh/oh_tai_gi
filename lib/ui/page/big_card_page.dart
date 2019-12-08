import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/ui/component/big_card.dart';

import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/utils/utils.dart';

const bool IS_DEBUG = false;

class BigCardPage extends StatefulWidget {
  BigCardPage({Key key, this.destination, this.vocabularyList, this.switchToList}) : super(key: key);

  final Destination destination;
  final VocabularyList vocabularyList;
  final Function switchToList;

  @override
  _BigCardPageState createState() => _BigCardPageState();
}

class _BigCardPageState extends State<BigCardPage> {
  int _index = 0;
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  _BigCardPageState();

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    vp = VocabularyProvider();
    await vp.open();
    if(widget.vocabularyList == null) {
      List<Vocabulary> vs = await vp.getVocabularyList();
      if(vs.length > 0) {
        _appendVocabularyList(vs);
        return;
      }
      String contents = await getFileData("assets/dict/dict-twblg.json");
      vs.insertAll(0, json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList());
      contents = await getFileData("assets/dict/dict-twblg-ext.json");
      vs.insertAll(0, json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList());
      vs = await vp.insertAll(vs);
      _appendVocabularyList(vs);
    } else {
      List<Vocabulary> vs = [];
      for(int i = 0; i < widget.vocabularyList.list.length; ++i) {
        Vocabulary v = await vp.getVocabularyWithTitle(widget.vocabularyList.list[i]);
        if(v != null)
          vs.add(v);
      }
      _appendVocabularyList(vs);
    }
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
    Vocabulary v;
    if(_index < vocabularies.length) {
      v = vocabularies[_index];
    }
    return Scaffold(
      appBar: AppBar(
        title: widget.switchToList!=null?Text(widget.vocabularyList.title):Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Dismissible(
          background: Card(
            color: Colors.green[300],
            child:Container(
              padding: const EdgeInsets.only(left: 15),
              alignment: Alignment.centerLeft,
              child:Image.asset("assets/launcher/icon_pos.png")
            )
          ),
          secondaryBackground: Card(
            color: Colors.yellow[300],
            child:Container(
              padding: const EdgeInsets.only(right: 15),
              alignment: Alignment.centerRight,
              child:Image.asset("assets/launcher/icon_neg.png")
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
      floatingActionButton: widget.switchToList!=null?FloatingActionButton(
        onPressed: () => widget.switchToList(context),
        tooltip: 'switchToList',
        child: Icon(Icons.list),
      ):null,
    );
  }
}
