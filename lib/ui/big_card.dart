import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';

class BigCard extends StatelessWidget {
  final Vocabulary _vocabulary;
  BigCard(this._vocabulary,{Key key}) : super(key: key);

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
    if(_vocabulary == null)
      return Center(child: CircularProgressIndicator());

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
              Text(
                _vocabulary.title,
                style: Theme.of(context).textTheme.display2,
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