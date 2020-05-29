import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';

import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_card.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_foldable_card.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const bool IS_DEBUG = false;

class SmallCardListPage extends StatefulWidget {
  SmallCardListPage({Key key, this.destination, this.vocabularyList, this.switchToLearning, this.setController}) : super(key: key);

  final VocabularyList vocabularyList;
  final Destination destination;
  final Function switchToLearning;
  final Function setController;

  @override
  SmallCardListPageState createState() => SmallCardListPageState();
}

class SmallCardListPageState extends State<SmallCardListPage> {
  List<Vocabulary> vocabularies = [];
  VocabularyProvider vp;
  bool shouldReload = true;
  YoutubePlayerController _controller;
  SmallCardListPageState();
  @override
  void initState() {
    super.initState();
    if(widget != null && widget.vocabularyList != null) {
      refresh();
      if(widget.vocabularyList.cover != null && widget.vocabularyList.cover.length > 0) {
        _controller = YoutubePlayerController(
            initialVideoId: YoutubePlayer.convertUrlToId(widget.vocabularyList.cover),
            flags: YoutubePlayerFlags(
                mute: false,
                autoPlay: false,
                forceHideAnnotation: false
            ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(widget.setController != null && _controller != null) {
      widget.setController(_controller);
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

    if(widget.vocabularyList == null) {
      List<Vocabulary> vs = await vp.getVocabularyList(offset: this.vocabularies.length, where: '$columnLearnt > ?', whereArgs: [0]);
      _appendVocabularyList(vs);
    } else {
      List<Vocabulary> vs = [];
      for(int i = 0; i < widget.vocabularyList.list.length; ++i) {
        Vocabulary v = await vp.getVocabularyWithTitle(widget.vocabularyList.list[i]);
        if(v != null)
          vs.add(v);
      }
      _appendVocabularyList(vs);
    }
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
          if (scrollInfo.depth == 0 &&
            widget.vocabularyList == null &&
            shouldReload &&
            scrollInfo.metrics.pixels ==
              scrollInfo.metrics.maxScrollExtent) {
            retrieveVocabularyList();
          }
          return false;
        },
      );

      if(widget.switchToLearning!=null && OTGConfig.get(OTGConfig.discoveryToggle, 0) == 0) {
        FeatureDiscovery.discoverFeatures(
          context,
          const <String>{
            "switch_to_learning",
          },
        );
      }
      
      if(_controller != null) {
        body = Column(
          children: <Widget>[
            Flexible(child:YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.amber,
                progressColors: ProgressBarColors(
                    playedColor: Colors.amber,
                    handleColor: Colors.amberAccent,
                ),
            ), flex: 1,),
            Flexible(child:body, flex: 3),
          ],
        );
      }
    } else if(widget.vocabularyList != null) {
      body = Center(child: CircularProgressIndicator());
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
        title: widget.switchToLearning!=null?Text(widget.vocabularyList.title):Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
      floatingActionButton: widget.switchToLearning!=null?
        DescribedFeatureOverlay(
          featureId: 'switch_to_learning', // Unique id that identifies this overlay.
          tapTarget: const Icon(Icons.local_library), // The widget that will be displayed as the tap target.
          title: Text('進入學習模式'),
          description: Text('點擊進入字卡學習模式，\n也可以選擇直接瀏覽此主題的字彙。'),
          backgroundColor: Theme.of(context).primaryColor,
          targetColor: Colors.white,
          textColor: Colors.white,
          contentLocation: ContentLocation.above,
          onComplete: () async {
            OTGConfig.setKeyInt(OTGConfig.discoveryToggle, 1);
            return true;
          },
          onDismiss: () async {
            OTGConfig.setKeyInt(OTGConfig.discoveryToggle, 1);
            return true;
          },
          child: FloatingActionButton(
            onPressed: () => widget.switchToLearning(context),
            tooltip: '開始學習',
            child: Icon(Icons.local_library),
          )
        ):
        null,
    );
  }
}
