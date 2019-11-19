import 'package:flutter/material.dart';
import 'package:oh_tai_gi/audio_player_holder.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';

class SmallCard extends StatelessWidget {
  final Vocabulary _vocabulary;
  SmallCard(this._vocabulary,{Key key}) : super(key: key);

  Widget buildBody(BuildContext context) {
    List<Widget> children = <Widget>[];
    for(int i = 0; i < _vocabulary.heteronyms.length; ++i) {
      children.add(Text(
        "${i+1}: ${_vocabulary.heteronyms[i].trs}" ,
        style: Theme.of(context).textTheme.body2,
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
      flex: 7, child: ListView(children: children), fit: FlexFit.tight
    );
  }


  void _tryToPlayAudio(Vocabulary vocabulary, BuildContext context) async {
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.of(context).tryToPlayAudio(vocabulary.heteronyms[i].aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_vocabulary == null)
      return Center(child: CircularProgressIndicator());

    return Card(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: <Widget>[
            Flexible(child: Text(
              _vocabulary.title,
              style: Theme.of(context).textTheme.body2,
            ), flex: 3, fit: FlexFit.tight),
            Flexible(child: InkWell(
              splashColor: Colors.blue.withAlpha(30),
              onTap: (){
                _tryToPlayAudio(_vocabulary, context);
              },
              child: Icon(Icons.volume_up, size: 25,),
            ), flex: 2, fit: FlexFit.loose),
            buildBody(context),
          ]
        ),
      ),
    );
  }
}