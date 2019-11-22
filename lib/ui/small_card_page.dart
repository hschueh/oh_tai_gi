import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/small_card.dart';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';

const bool IS_DEBUG = false;

class SmallCardListPage extends StatefulWidget {
  SmallCardListPage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  SmallCardListPageState createState() => SmallCardListPageState();
}

class SmallCardListPageState extends State<SmallCardListPage> {
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  SmallCardListPageState();

  refresh() {
    retrieveVocabularyList();
  }

  void retrieveVocabularyList() async {
    if(vp == null) {
      vp = VocabularyProvider();
      await vp.open('vocabulary.db');
    }
    List<Vocabulary> vs = await vp.getVocabularyList(where: '$columnLearnt > ?', whereArgs: ["0"]);
    if(vs.length > 0) {
      _setVocabularyList(vs);
      return;
    }
  }

  void _setVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies = vs;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(vocabularies.length > 0) {
      body = ListView.builder(
        itemCount: vocabularies.length,
        itemBuilder: (context, position) {
          return SmallCard(vocabularies[position], key: UniqueKey());
        },
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mood_bad),
            Text("你還沒有學過的單詞！", style: Theme.of(context).textTheme.body1,)
          ],
        )
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _next(true),
      //   tooltip: 'Increment',
      //   child: Icon(Icons.thumb_up),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
