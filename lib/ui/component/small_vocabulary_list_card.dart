import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

class SmallVocabularyListCard extends StatelessWidget {
  final VocabularyList _vocabularyList;
  final Function _onTap;
  final bool isNew;
  SmallVocabularyListCard(this._vocabularyList, this.isNew, this._onTap, {Key key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    if(_vocabularyList == null)
      return Center(child: CircularProgressIndicator());
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        splashColor: Colors.blue[200].withAlpha(30),
        onTap: () => _onTap(context, _vocabularyList),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child:Text(
                _vocabularyList.title,
                style: Theme.of(context).textTheme.headline.copyWith(
                  fontFamilyFallback: ["MOEDICT"],
                ),
              )),
              Align(
                alignment: Alignment.bottomRight,
                child:Text(
                _vocabularyList.provider,
                style: Theme.of(context).textTheme.subhead,
              )),
              isNew
                ? Align(
                  alignment: Alignment.topRight,
                  child:Icon(Icons.new_releases),
                )
                : SizedBox()
            ]
          ),
        )
      ),
    );
  }
}