import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';

class BigCard extends StatelessWidget {
  final Vocabulary _vocabulary;
  final bool isEnd;
  BigCard(this._vocabulary,{Key key, this.isEnd = false}) : super(key: key);

  void _tryToPlayAudio(Vocabulary vocabulary, BuildContext context) async {
    for(int i = 0; i < vocabulary.heteronyms.length; ++i) {
      await AudioPlayerHolder.tryToPlayAudio(vocabulary.heteronyms[i].aid);
    }
  }

  ListView buildBody(BuildContext context) {
    List<Widget> children = <Widget>[];
    for(int i = 0; i < _vocabulary.heteronyms.length; ++i) {
      children.add(Text(
        "${i+1}: ${_vocabulary.heteronyms[i].trs}" ,
        style: Theme.of(context).textTheme.display1,
      ));
      for(int j = 0; j < _vocabulary.heteronyms[i].definitions.length; ++j) {
        children.add(
          Row(
            children: <Widget>[
              SizedBox(width: 10.0),
              Flexible(child:Text(
                "• ${_vocabulary.heteronyms[i].definitions[j].def}" ,
                style: Theme.of(context).textTheme.headline,
              )),
            ],
          )
        );
      }
    }
    return ListView(children: children);
  }

  @override
  Widget build(BuildContext context) {
    if(_vocabulary == null) {
      if(isEnd) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/launcher/icon_tired.png"),
            Text("學完囉，返回上個頁面挑選其他的字彙表或馬上開始複習吧", style: Theme.of(context).textTheme.body1,)
          ],
        );
      }
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: (){},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Text(
                    _vocabulary.title,
                    style: Theme.of(context).textTheme.display2,
                  ),
                  SizedBox(width: 15,),
                  InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: (){
                      _tryToPlayAudio(_vocabulary, context);
                    },
                    child: Icon(Icons.volume_up, size: 35,),
                  ),
                ]
              ),
              Expanded(
                child: buildBody(context)
              ),
            ]
          ),
        ),
      ),
    );
  }
}