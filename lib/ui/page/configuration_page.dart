import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';


const bool IS_DEBUG = false;

class ConfigurationPage extends StatefulWidget {
  ConfigurationPage({Key key, this.destination}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Destination destination;

  @override
  _ConfigurationPageState createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  int _autoPlayAudio;
  int _playAudioInGame;

  _ConfigurationPageState();
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _autoPlayAudio = OTGConfig.of(context).get(OTGConfig.keyAutoPlayAudio, 0);
      _playAudioInGame = OTGConfig.of(context).get(OTGConfig.keyPlayAudioInGame, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Container(
        padding: EdgeInsets.all(5.0),
        child: ListView(
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:Text("自動播放/預載語音", style: Theme.of(context).textTheme.title)),
              FlatButton(
                color: _autoPlayAudio<2?Colors.cyan:Colors.grey,
                padding: EdgeInsets.all(8.0),
                splashColor: Colors.cyanAccent,
                onPressed: () {
                  setState(() {
                    _autoPlayAudio = ((_autoPlayAudio)+1)%OTGConfig.valueAutoPlayAudio.length;
                    OTGConfig.of(context).setKeyInt(OTGConfig.keyAutoPlayAudio, _autoPlayAudio);
                  });
                },
                child: Text(
                  OTGConfig.valueAutoPlayAudio[_autoPlayAudio], style: Theme.of(context).textTheme.title
                ),
              )
            ],),
            Row(children: <Widget>[
              Expanded(child:Text("翻牌遊戲播放語音", style: Theme.of(context).textTheme.title)),
              FlatButton(
                color: Colors.cyan,
                padding: EdgeInsets.all(8.0),
                splashColor: Colors.cyanAccent,
                onPressed: () {
                  setState(() {
                    _playAudioInGame = ((_playAudioInGame)+1)%OTGConfig.valuePlayAudioInGame.length;
                    OTGConfig.of(context).setKeyInt(OTGConfig.keyPlayAudioInGame, _playAudioInGame);
                  });
                },
                child: Text(
                  OTGConfig.valuePlayAudioInGame[_playAudioInGame], style: Theme.of(context).textTheme.title
                ),
              )
            ],),
            Row(children: <Widget>[
              Expanded(child:Text("清空學習紀錄", style: Theme.of(context).textTheme.title)),
              FlatButton(
                color: Colors.cyan,
                padding: EdgeInsets.all(8.0),
                splashColor: Colors.cyanAccent,
                onPressed: () {
                  VocabularyProvider().getVocabularyList(limit: 100000, where: '$columnLearnt > ?', whereArgs: [0])
                    .then((List<Vocabulary> vs){
                      vs = vs.map((v){
                        v.learnt = 0;
                        return v;
                      }).toList();
                      VocabularyProvider().updateAll(vs).then(
                        (result) => print("Clean learnt finished.")
                      );
                    });
                },
                child: Text(
                  "清空", style: Theme.of(context).textTheme.title
                ),
              )
            ],),
          ],
        )
      ),
    );
  }
}
