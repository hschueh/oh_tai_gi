import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class SmallVocabularyFoldableCard extends StatefulWidget {
  final Vocabulary _vocabulary;
  SmallVocabularyFoldableCard(this._vocabulary,{Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SmallVocabularyFoldableCardState();
}

class _SmallVocabularyFoldableCardState extends State<SmallVocabularyFoldableCard> {
  bool _folded = true;

  _SmallVocabularyFoldableCardState();

  Widget buildBody(BuildContext context) {
    List<Widget> children = <Widget>[];
    for(int i = 0; i < widget._vocabulary.heteronyms.length; ++i) {
      children.add(Text(
        "${widget._vocabulary.heteronyms[i].trs}" ,
        style: Theme.of(context).textTheme.subhead,
      ));
      for(int j = 0; j < widget._vocabulary.heteronyms[i].definitions.length; ++j) {
        children.add(
          Row(
            children: <Widget>[
              SizedBox(width: 5.0),
              Flexible(child:Text(
                "• ${widget._vocabulary.heteronyms[i].definitions[j].def}" ,
                style: Theme.of(context).textTheme.body1,
              )),
            ],
          )
        );
      }
    }
    return Flexible(
      flex: 7,
      fit: FlexFit.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
      ),
    );
  }


  void _tryToPlayAudio(Vocabulary vocabulary, BuildContext context) async {
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(vocabulary.heteronyms[i].aid);
    }
  }

  void _tryToPrepareAudio(Vocabulary vocabulary, BuildContext context) async {
    int connectivity = await getConnectivityResult();
    int autoPlaySetting = OTGConfig.of(context).get(OTGConfig.keyAutoPlayAudio, 0);
    if(autoPlaySetting > connectivity)
      return;
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.prepareAudio(vocabulary.heteronyms[i].aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(widget._vocabulary == null)
      return Center(child: CircularProgressIndicator());
      // Not working properly.
      // _tryToPrepareAudio(_vocabulary, context);
      return Card(
        margin: const EdgeInsets.all(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ConstrainedBox(
            constraints: new BoxConstraints(
              minHeight: 100.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    widget._vocabulary.title,
                    style: Theme.of(context).textTheme.subhead,
                  ),
                  flex: 2,
                  fit: FlexFit.tight,
                ),
                Flexible(
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: (){
                      _tryToPlayAudio(widget._vocabulary, context);
                    },
                    child: Icon(Icons.volume_up, size: 25,),
                  ),
                  flex: 1,
                  fit: FlexFit.tight,
                ),
                buildBody(context),
              ]
            ),
          )
        ),
      );
  }
}
