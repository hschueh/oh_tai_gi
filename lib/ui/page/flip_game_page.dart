import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/flip_card.dart';
import 'package:oh_tai_gi/ui/component/flippable_card.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';

class FlipGamePage extends StatefulWidget {
  const FlipGamePage({super.key, required this.destination});

  final Destination destination;

  @override
  FlipGamePageState createState() => FlipGamePageState();
}

class FlipGamePageState extends State<FlipGamePage> {
  static const int GAME_SIZE = 6;
  final List<Vocabulary> vocabularies = [];
  final List<int> shuffler = List<int>.generate(GAME_SIZE * 2, (i) => i);
  final List<GlobalKey<FlipCardState>> keys =
      List<GlobalKey<FlipCardState>>.generate(
          GAME_SIZE * 2, (i) => GlobalKey<FlipCardState>());
  final VocabularyProvider vp = VocabularyProvider();
  int correctCnt = 0;
  GlobalKey<FlipCardState>? flippedKey;
  Vocabulary? flippedVocabulary;

  void onFlip(GlobalKey<FlipCardState> key, Vocabulary vocabulary) {
    final previousKey = flippedKey;
    final previousVocabulary = flippedVocabulary;
    if (previousKey == null || previousVocabulary == null) {
      flippedKey = key;
      flippedVocabulary = vocabulary;
      return;
    }

    if (vocabulary.id != previousVocabulary.id) {
      previousKey.currentState?.toggleCard();
      key.currentState?.toggleCard();
    } else {
      ++correctCnt;
      if (correctCnt == GAME_SIZE) {
        correctCnt = 0;
        AudioPlayerHolder.playLocal('win.wav');
        final vs = vocabularies.sublist(0, GAME_SIZE);
        for (final v in vs) {
          v.learnt = v.learnt + 1;
        }
        vp.updateAll(vs).then((_) => refresh());
      } else {
        AudioPlayerHolder.playLocal('correct.wav');
      }
    }
    flippedKey = null;
    flippedVocabulary = null;
  }

  void refresh() {
    for (final key in keys) {
      // Toggle back to the front.
      final state = key.currentState;
      if (state != null && !state.isFront) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          key.currentState?.toggleCard();
        });
      }
    }
    vocabularies.clear();
    flippedKey = null;
    flippedVocabulary = null;
    correctCnt = 0;
    retrieveVocabularyList();
    shuffler.shuffle();
  }

  Future<void> retrieveVocabularyList() async {
    await vp.open();
    final vs = await vp.getVocabularyList(
        where: '$columnLearnt > ?', whereArgs: [0], limit: GAME_SIZE);
    if (!mounted) return;
    setState(() => vocabularies.addAll(vs));
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (vocabularies.length >= GAME_SIZE) {
      body = GridView.builder(
        itemCount: GAME_SIZE * 2,
        itemBuilder: (context, position) {
          final realPos = shuffler[position];
          return FlippableCard(vocabularies[realPos ~/ 2], realPos % 2 == 0,
              onFlip, keys[realPos]);
        },
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      );
    } else {
      body = Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/launcher/icon_tired.png'),
            Text('學過的單詞還不足以開始遊戲！',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: body,
    );
  }
}
