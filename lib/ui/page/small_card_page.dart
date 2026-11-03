import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_foldable_card.dart';
import 'package:oh_tai_gi/ui/page/big_card_page.dart' show SwitchMode;
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Lists either the learnt vocabularies ("學習歷程") or the vocabularies of one
/// vocabulary list, with its YouTube video on top when it has one.
class SmallCardListPage extends StatefulWidget {
  const SmallCardListPage(
      {super.key,
      required this.destination,
      this.vocabularyList,
      this.switchToLearning,
      this.setController,
      this.clearController});

  final VocabularyList? vocabularyList;
  final Destination destination;
  final SwitchMode? switchToLearning;
  final ValueChanged<YoutubePlayerController>? setController;
  final ValueChanged<YoutubePlayerController>? clearController;

  @override
  SmallCardListPageState createState() => SmallCardListPageState();
}

class SmallCardListPageState extends State<SmallCardListPage> {
  final List<Vocabulary> vocabularies = [];
  final VocabularyProvider vp = VocabularyProvider();
  bool shouldReload = true;
  bool _discoveryStarted = false;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final list = widget.vocabularyList;
    if (list != null) {
      refresh();
      final videoId = list.cover.isNotEmpty
          ? YoutubePlayerController.convertUrlToId(list.cover)
          : null;
      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            captionLanguage: 'zh',
            showFullscreenButton: true,
          ),
        );
      }
    }
    final controller = _controller;
    if (controller != null) widget.setController?.call(controller);
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      widget.clearController?.call(controller);
      controller.close();
    }
    super.dispose();
  }

  void refresh() {
    vocabularies.clear();
    retrieveVocabularyList();
  }

  Future<void> retrieveVocabularyList() async {
    shouldReload = false;
    await vp.open();
    final list = widget.vocabularyList;
    final List<Vocabulary> vs;
    if (list == null) {
      vs = await vp.getVocabularyList(
          offset: vocabularies.length,
          where: '$columnLearnt > ?',
          whereArgs: [0]);
    } else {
      vs = await vp.getVocabulariesWithTitles(list.list);
    }
    if (!mounted) return;
    setState(() {
      vocabularies.addAll(vs);
      if (vs.isNotEmpty) shouldReload = true;
    });
  }

  void _maybeStartFeatureDiscovery() {
    if (_discoveryStarted ||
        widget.switchToLearning == null ||
        OTGConfig.get(OTGConfig.discoveryToggle, 0) != 0) {
      return;
    }
    _discoveryStarted = true;
    // Must not be started while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FeatureDiscovery.discoverFeatures(context, const {'switch_to_learning'});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.vocabularyList;
    Widget body;
    if (vocabularies.isNotEmpty) {
      body = NotificationListener<ScrollNotification>(
        child: ListView.builder(
          itemCount: vocabularies.length,
          itemBuilder: (context, position) {
            return SmallVocabularyFoldableCard(vocabularies[position],
                key: ObjectKey(vocabularies[position]));
          },
        ),
        onNotification: (scrollInfo) {
          if (scrollInfo.depth == 0 &&
              list == null &&
              shouldReload &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            retrieveVocabularyList();
          }
          return _controller != null;
        },
      );

      _maybeStartFeatureDiscovery();

      final controller = _controller;
      if (controller != null) {
        body = Column(
          children: [
            Flexible(
              flex: 1,
              child: YoutubePlayer(controller: controller),
            ),
            Flexible(flex: 3, child: body),
          ],
        );
      }
    } else if (list != null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/launcher/icon_tired.png'),
            Text('你還沒有學過的單詞！',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    final switchToLearning = widget.switchToLearning;
    return Scaffold(
      appBar: AppBar(
        title: Text(switchToLearning != null && list != null
            ? list.title
            : widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
      floatingActionButton: switchToLearning != null
          ? DescribedFeatureOverlay(
              featureId: 'switch_to_learning',
              tapTarget: const Icon(Icons.local_library),
              title: const Text('進入學習模式'),
              description: const Text('點擊進入字卡學習模式，\n也可以選擇直接瀏覽此主題的字彙。'),
              backgroundColor: Theme.of(context).primaryColor,
              targetColor: Colors.white,
              textColor: Colors.white,
              contentLocation: ContentLocation.above,
              onComplete: () async {
                await OTGConfig.setKeyInt(OTGConfig.discoveryToggle, 1);
                return true;
              },
              onDismiss: () async {
                await OTGConfig.setKeyInt(OTGConfig.discoveryToggle, 1);
                return true;
              },
              child: FloatingActionButton(
                onPressed: () => switchToLearning(context),
                tooltip: '開始學習',
                child: const Icon(Icons.local_library),
              ),
            )
          : null,
    );
  }
}
