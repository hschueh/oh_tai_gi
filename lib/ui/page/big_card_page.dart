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
      String dbVer = OTGConfig.of(context).get(OTGConfig.keyDBVer, "0");
      List<Vocabulary> vs;
      if(dbVer == "20200103") {
        List<Vocabulary> vs = await vp.getVocabularyList();
        if(vs.length > 0) {
          _appendVocabularyList(vs);
          return;
        }
      } else {
        // TODO: Update vocabulary library without wipe learning record.
        await vp.deleteAll();
        vs = [];
      }
      String contents = await getFileData("assets/dict/dict-twblg-merge.json");
      vs.insertAll(0, json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList());
      if(vs.length > 0) {
        vs = await vp.insertAll(vs);
        OTGConfig.of(context).setKeyString(OTGConfig.keyDBVer, "20200103");
        _appendVocabularyList(vs);
      }
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

  void retrieveNextBatch() async {
      List<Vocabulary> vs = await vp.getVocabularyList(offset: vocabularies.length);
      if(vs.length > 0) {
        _appendVocabularyList(vs);
        return;
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
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(v.heteronyms[i].aid);
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
      if(_index >= vocabularies.length)
        retrieveNextBatch();
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
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              margin: const EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 0),
              child: Dismissible(
                background: Card(
                  color: Colors.green[300],
                  child:Container(
                    padding: const EdgeInsets.only(left: 15),
                    alignment: Alignment.centerLeft,
                    child: Image.asset("assets/launcher/icon_pos.png",
                      filterQuality: FilterQuality.high,
                      scale: 1.2,
                    ),
                  )
                ),
                secondaryBackground: Card(
                  color: Colors.yellow[300],
                  child:Container(
                    padding: const EdgeInsets.only(right: 15),
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      "assets/launcher/icon_neg.png",
                      filterQuality: FilterQuality.high,
                      scale: 1.2,
                    ),
                  )
                ),
                onDismissed: (DismissDirection direction){
                  if(direction == DismissDirection.startToEnd) {
                    _next(true);
                  } else if(direction == DismissDirection.endToStart) {
                    _next(false);
                  }
                },
                child:BigCard(v, isEnd: widget.vocabularyList != null &&
                                        _index >= widget.vocabularyList.list.length &&
                                        _index >= vocabularies.length,),
                key: UniqueKey(),
              ),
            ),
          ),
          _index==0?Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:[
              Icon(Icons.help),
              Text(
                "記得了就往右滑，還沒記住往左滑",
                style: Theme.of(context).textTheme.subtitle
              )
            ]
          ):SizedBox(width: 0, height: 0,),
        ]
      ),
      floatingActionButton: widget.switchToList!=null?FloatingActionButton(
        onPressed: () => widget.switchToList(context),
        tooltip: 'switchToList',
        child: Icon(Icons.list),
      ):null,
    );
  }
}
