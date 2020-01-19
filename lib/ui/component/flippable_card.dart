import 'package:flutter/material.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:flip_card/flip_card.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';

class FlippableCard extends StatelessWidget {
  final Vocabulary vocabulary;
  final bool isFirst;
  final GlobalKey<FlipCardState> globalKey;
  final Function(GlobalKey<FlipCardState>, Vocabulary) onFlip;
  FlippableCard(this.vocabulary, this.isFirst, this.onFlip, this.globalKey, {Key key}) : super(key: key);

  Widget buildBody(BuildContext context) {
    if(isFirst)
      return Center(child: Text(
          vocabulary.title,
          style: Theme.of(context).textTheme.headline,
        ));
    List<Widget> children = <Widget>[];
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      children.add(Text(
        "${vocabulary.heteronyms[i].trs}" ,
        style: Theme.of(context).textTheme.headline,
      ));
      for(int j = 0; j < vocabulary.heteronyms[i].definitions.length; ++j) {
        children.add(Text(
          "• ${vocabulary.heteronyms[i].definitions[j].def}" ,
          style: Theme.of(context).textTheme.subhead,
        ));
      }
    }
    return Container(
        child: ListView(children: children)
      );
  }

  void _tryToPlayAudio(Vocabulary vocabulary, BuildContext context) async {
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(vocabulary.heteronyms[i].aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(vocabulary == null)
      return Center(child: CircularProgressIndicator());
    // Not working properly.
    // _tryToPrepareAudio(_vocabulary, context);
    return FlipCard(
      key: globalKey,
      flipOnTouch: false,
      onFlipDone: (flipped){
        if(!flipped) onFlip(globalKey, vocabulary);
      },
      front: Container(
        margin: EdgeInsets.all(2),
        height: 100,
        width: 100,
        child: Card(
          child: InkWell(
            splashColor: Colors.orangeAccent.withAlpha(30),
            onTap: (){
              globalKey.currentState.toggleCard();
              int playAudio = OTGConfig.of(context).get(OTGConfig.keyPlayAudioInGame, 0);
              if(playAudio == 0)
                return;
              _tryToPlayAudio(vocabulary, context);
            }),
          color: Colors.orange[200],
        ),
      ),
      back: Container(
        margin: EdgeInsets.all(2),
        height: 100,
        width: 100,
        child: Card(color: Colors.orange[200], child: buildBody(context),)
      )
    );
  }
}