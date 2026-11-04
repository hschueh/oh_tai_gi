import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/big_card.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:oh_tai_gi/utils/utils.dart';

typedef SwitchMode = void Function(BuildContext context);

class BigCardPage extends StatefulWidget {
  const BigCardPage(
      {super.key,
      required this.destination,
      this.vocabularyList,
      this.switchToList});

  final Destination destination;
  final VocabularyList? vocabularyList;
  final SwitchMode? switchToList;

  @override
  State<BigCardPage> createState() => _BigCardPageState();
}

class _BigCardPageState extends State<BigCardPage> {
  int _index = 0;
  final List<Vocabulary> vocabularies = [];
  final VocabularyProvider vp = VocabularyProvider();
  bool isFirst = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await vp.open();
    final list = widget.vocabularyList;
    if (list == null) {
      _appendVocabularyList(await vp.getVocabularyList());
    } else {
      _appendVocabularyList(await vp.getVocabulariesWithTitles(list.list));
    }
    _loaded = true;
  }

  Future<void> retrieveNextBatch() async {
    // A vocabulary list is loaded at once; only the random mode is paged.
    if (widget.vocabularyList != null) return;
    final vs = await vp.getVocabularyList(offset: vocabularies.length);
    if (vs.isNotEmpty) _appendVocabularyList(vs);
  }

  Future<void> _tryToPlayAudio() async {
    if (_index >= vocabularies.length) return;
    if (isFirst) {
      isFirst = false;
      return;
    }
    final connectivity = await getConnectivityResult();
    final autoPlaySetting = OTGConfig.get(OTGConfig.keyAutoPlayAudio, 0);
    if (autoPlaySetting > connectivity) return;
    final v = vocabularies[_index];
    for (final heteronym in v.heteronyms) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(heteronym.aid);
    }
  }

  void _next(bool thumbUp) {
    final v = vocabularies[_index];
    v.learnt = v.learnt + 1;
    vp.update(v);
    setState(() => _index++);
    if (_index >= vocabularies.length) retrieveNextBatch();
    _tryToPlayAudio();
  }

  void _appendVocabularyList(List<Vocabulary> vs) {
    if (!mounted) return;
    setState(() => vocabularies.addAll(vs));
    _tryToPlayAudio();
  }

  @override
  Widget build(BuildContext context) {
    final Vocabulary? v =
        _index < vocabularies.length ? vocabularies[_index] : null;
    final list = widget.vocabularyList;
    final switchToList = widget.switchToList;
    return Scaffold(
      appBar: AppBar(
        title: Text(switchToList != null && list != null
            ? list.title
            : widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Container(
              margin: const EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 0),
              child: Dismissible(
                key: UniqueKey(),
                // Nothing to swipe while loading or after the last card.
                direction: v == null
                    ? DismissDirection.none
                    : DismissDirection.horizontal,
                background: Card(
                  color: Colors.green[300],
                  child: Container(
                    padding: const EdgeInsets.only(left: 15),
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/launcher/icon_pos.png',
                      filterQuality: FilterQuality.high,
                      scale: 1.2,
                    ),
                  ),
                ),
                secondaryBackground: Card(
                  color: Colors.yellow[300],
                  child: Container(
                    padding: const EdgeInsets.only(right: 15),
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/launcher/icon_neg.png',
                      filterQuality: FilterQuality.high,
                      scale: 1.2,
                    ),
                  ),
                ),
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    _next(true);
                  } else if (direction == DismissDirection.endToStart) {
                    _next(false);
                  }
                },
                child: BigCard(
                  v,
                  // Titles missing from the dictionary are skipped, so
                  // compare against what was actually loaded.
                  isEnd: list != null &&
                      _loaded &&
                      _index >= vocabularies.length,
                ),
              ),
            ),
          ),
          if (_index == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.help),
                Text('記得了就往右滑，還沒記住往左滑',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
        ],
      ),
      floatingActionButton: switchToList != null
          ? FloatingActionButton(
              onPressed: () => switchToList(context),
              tooltip: 'switchToList',
              child: const Icon(Icons.list),
            )
          : null,
    );
  }
}
