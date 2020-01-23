import 'package:flutter/material.dart';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_foldable_card.dart';

const bool IS_DEBUG = false;

class SearchPage extends StatefulWidget {
  SearchPage({Key key, this.destination}) : super(key: key);

  final Destination destination;

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  bool shouldReload = true;
  bool toggleSearch = true;
  SearchPageState();
  @override
  void initState() {
    super.initState();
    if(widget != null) {
      refresh();
    }
  }

  refresh() {
    this.vocabularies.clear();
    retrieveVocabularyList();
  }

  void retrieveVocabularyList() async {
    shouldReload = false;
    if(vp == null) {
      vp = VocabularyProvider();
      await vp.open();
    }
    //TODO: use keyword.
    List<Vocabulary> vs = await vp.getVocabularyList(offset: this.vocabularies.length, where: '$columnLearnt > ?', whereArgs: [0]);
    _appendVocabularyList(vs);
  }

  void _appendVocabularyList(List<Vocabulary> vs) {
    setState(() {
      this.vocabularies.addAll(vs);
      if(vs.length > 0)
        shouldReload = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if(vocabularies.length > 0) {
      body = NotificationListener<ScrollNotification>(
        child: ListView.builder(
          itemCount: vocabularies.length,
          itemBuilder: (context, position) {
            return SmallVocabularyFoldableCard(vocabularies[position], key: UniqueKey());
          },
        ),
        onNotification: (ScrollNotification scrollInfo) {
          if (shouldReload &&
              scrollInfo.metrics.pixels ==
              scrollInfo.metrics.maxScrollExtent) {
            retrieveVocabularyList();
          }
          return true;
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
            Text("找不到相關詞彙", style: Theme.of(context).textTheme.body1,)
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
      floatingActionButton: this.toggleSearch?
        FloatingActionButton(
          backgroundColor: widget.destination.color,
          onPressed: () => setState((){
            this.toggleSearch = !this.toggleSearch;
          }),
          tooltip: '搜尋',
          child: Icon(Icons.search),
        ):
        Container(
          height: 55,
          width: MediaQuery.of(context).size.width * 0.9,
            child: new RawMaterialButton(
              padding: const EdgeInsets.only(left:25),
              shape: new RoundedRectangleBorder(borderRadius: BorderRadius.circular(27.5)),
              fillColor: widget.destination.color,
              splashColor: widget.destination.color,
              elevation: 0.0,
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 7,
                    child:TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '輸入關鍵字'
                      ),
                    )
                  ),
                  Expanded(
                    flex: 1,
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              onPressed: () => setState((){
                this.toggleSearch = !this.toggleSearch;
              }),
            )
        ),
        // RaisedButton(
        //   child: Wrap(
        //     children: [
        //       TextField(
        //         decoration: InputDecoration(
        //           border: InputBorder.none,
        //           hintText: '輸入關鍵字'
        //         ),
        //       ),
        //       Icon(Icons.arrow_forward),
        //     ]
        //   ), onPressed: () => setState((){
        //     this.toggleSearch = !this.toggleSearch;
        //   }),
        // ),
    );
  }
}
