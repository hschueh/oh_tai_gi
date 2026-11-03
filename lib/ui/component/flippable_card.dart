import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/ui/component/flip_card.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';

typedef OnCardFlip = void Function(
    GlobalKey<FlipCardState> key, Vocabulary vocabulary);

class FlippableCard extends StatelessWidget {
  const FlippableCard(this.vocabulary, this.isFirst, this.onFlip, this.globalKey,
      {super.key});

  final Vocabulary vocabulary;
  final bool isFirst;
  final GlobalKey<FlipCardState> globalKey;
  final OnCardFlip onFlip;

  Widget buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (isFirst) {
      return Center(
        child: Text(
          vocabulary.title,
          style: textTheme.headlineSmall
              ?.copyWith(fontFamilyFallback: const ['MOEDICT']),
        ),
      );
    }
    return ListView(
      children: [
        for (final heteronym in vocabulary.heteronyms) ...[
          Text(heteronym.trs ?? '', style: textTheme.headlineSmall),
          for (final definition in heteronym.definitions)
            Text('• ${definition.def ?? ''}', style: textTheme.titleMedium),
        ],
      ],
    );
  }

  Future<void> _tryToPlayAudio(Vocabulary vocabulary) async {
    for (final heteronym in vocabulary.heteronyms) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(heteronym.aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      key: globalKey,
      flipOnTouch: false,
      onFlipDone: (isFront) {
        if (!isFront) onFlip(globalKey, vocabulary);
      },
      front: Container(
        margin: const EdgeInsets.all(2),
        height: 100,
        width: 100,
        child: Card(
          color: Colors.orange[200],
          child: InkWell(
            splashColor: Colors.orangeAccent.withAlpha(30),
            onTap: () {
              globalKey.currentState?.toggleCard();
              final playAudio = OTGConfig.get(OTGConfig.keyPlayAudioInGame, 0);
              if (playAudio == 0) return;
              _tryToPlayAudio(vocabulary);
            },
          ),
        ),
      ),
      back: Container(
        margin: const EdgeInsets.all(2),
        height: 100,
        width: 100,
        child: Card(color: Colors.orange[200], child: buildBody(context)),
      ),
    );
  }
}
