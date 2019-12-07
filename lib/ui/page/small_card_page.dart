import 'package:flutter/material.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_card.dart';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';

const bool IS_DEBUG = false;

class SmallCardListPage extends StatefulWidget {
  SmallCardListPage({Key key, this.destination, this.vocabularyList, this.switchToLearning}) : super(key: key);

  final List<String> vocabularyList;
  final Destination destination;
  final Function switchToLearning;

  @override
  SmallCardListPageState createState() => SmallCardListPageState();
}

class SmallCardListPageState extends State<SmallCardListPage> {
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  SmallCardListPageState();
  @override
  void initState() {
    super.initState();
    if(widget != null && widget.vocabularyList != null) {
      refresh();
    }
  }

  refresh() {
    this.vocabularies.clear();
    retrieveVocabularyList();
  }

  void retrieveVocabularyList() async {
    if(vp == null) {
      vp = VocabularyProvider();
      await vp.open();
    }

    if(widget.vocabularyList == null) {
      List<Vocabulary> vs = await vp.getVocabularyList(where: '$columnLearnt > ?', whereArgs: [0]);
      _appendVocabularyList(vs);
    } else {
      List<Vocabulary> vs = [];
      for(int i = 0; i < widget.vocabularyList.length; ++i) {
        Vocabulary v = await vp.getVocabularyWithTitle(widget.vocabularyList[i]);
        if(v != null)
          vs.add(v);
      }
      _appendVocabularyList(vs);
    }
  }

  void _appendVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies.addAll(vs);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(vocabularies.length > 0) {
      body = ListView.builder(
        itemCount: vocabularies.length,
        itemBuilder: (context, position) {
          return SmallVocabularyCard(vocabularies[position], key: UniqueKey());
        },
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset("assets/launcher/icon_tired.png"),
            Text("你還沒有學過的單詞！", style: Theme.of(context).textTheme.body1,)
          ],
        )
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: widget.switchToLearning!=null?Text("Browse List"):Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
      floatingActionButton: widget.switchToLearning!=null?FloatingActionButton(
        onPressed: () => widget.switchToLearning(context),
        tooltip: 'switchToLearning',
        child: Icon(Icons.local_library),
      ):null,
    );
  }
}
