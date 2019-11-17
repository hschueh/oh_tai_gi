import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';

class BigCard extends StatelessWidget {
  final Vocabulary _vocabulary;
  BigCard(this._vocabulary,{Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(_vocabulary == null)
      return Card(child: Text("讀取中"));

    List<Widget> children = <Widget>[];
    String title = _vocabulary.title;
    for(int i = 0; i < _vocabulary.heteronyms.length; ++i) {
      children.add(Text(
        "${i+1}: ${_vocabulary.heteronyms[i].trs}" ,
        style: Theme.of(context).textTheme.display1,
      ));
      for(int j = 0; j < _vocabulary.heteronyms[i].definitions.length; ++j) {
        children.add(Text(
          "${_vocabulary.heteronyms[i].definitions[j].def}" ,
          style: Theme.of(context).textTheme.display1,
        ));
      }
    }

    return Card(
      child: Container(
        padding: EdgeInsets.all(8.0), 
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.display2,
              ),
              Expanded(
                child: ListView(
                  children: children,
                )
              ),
            ]
          ),
        ),
      ),
    );
  }
}