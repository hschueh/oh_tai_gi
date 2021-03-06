import 'package:flutter/material.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class SmallVocabularyCard extends StatelessWidget {
  final Vocabulary _vocabulary;
  SmallVocabularyCard(this._vocabulary,{Key key}) : super(key: key);

  Widget buildBody(BuildContext context) {
    List<Widget> children = <Widget>[];
    for(int i = 0; i < _vocabulary.heteronyms.length; ++i) {
      children.add(SelectableText(
        "${_vocabulary.heteronyms[i].trs}",
        toolbarOptions: ToolbarOptions(copy: true, selectAll: true),
        style: Theme.of(context).textTheme.subhead,
        maxLines: 1,
      ));
      for(int j = 0; j < _vocabulary.heteronyms[i].definitions.length; ++j) {
        children.add(
          Row(
            children: <Widget>[
              SizedBox(width: 5.0),
              Flexible(child:Text(
                "• ${_vocabulary.heteronyms[i].definitions[j].def}" ,
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
      child: ListView(children: children),
    );
  }


  void _tryToPlayAudio(Vocabulary vocabulary, BuildContext context) async {
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(vocabulary.heteronyms[i].aid);
    }
  }

  void _tryToPrepareAudio(Vocabulary vocabulary, BuildContext context) async {
    int connectivity = await getConnectivityResult();
    int autoPlaySetting = OTGConfig.get(OTGConfig.keyAutoPlayAudio, 0);
    if(autoPlaySetting > connectivity)
      return;
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.prepareAudio(vocabulary.heteronyms[i].aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_vocabulary == null)
      return Center(child: CircularProgressIndicator());
    // Not working properly.
    // _tryToPrepareAudio(_vocabulary, context);
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: SelectableText(
                _vocabulary.title,
                toolbarOptions: ToolbarOptions(copy: true, selectAll: true),
                style: Theme.of(context).textTheme.subhead.copyWith(
                  fontFamilyFallback: ["MOEDICT"],
                ),
                maxLines: 1,
              ),
              flex: 2,
              fit: FlexFit.tight,
            ),
            Flexible(
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: (){
                  _tryToPlayAudio(_vocabulary, context);
                },
                child: Icon(Icons.volume_up, size: 25,),
              ),
              flex: 1,
              fit: FlexFit.tight,
            ),
            buildBody(context),
          ]
        ),
      ),
    );
  }
}