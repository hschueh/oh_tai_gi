import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';

class BigCard extends StatelessWidget {
  const BigCard(this._vocabulary, {super.key, this.isEnd = false});

  final Vocabulary? _vocabulary;
  final bool isEnd;

  Future<void> _tryToPlayAudio(Vocabulary vocabulary) async {
    for (final heteronym in vocabulary.heteronyms) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(heteronym.aid);
    }
  }

  Widget buildBody(BuildContext context, Vocabulary vocabulary) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        if (vocabulary.chinese.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('[華] ${vocabulary.chinese}', style: textTheme.headlineSmall),
        ],
        for (final heteronym in vocabulary.heteronyms) ...[
          SelectableText(
            heteronym.trs ?? '',
            style: textTheme.headlineMedium,
            maxLines: 1,
          ),
          for (final definition in heteronym.definitions)
            Row(
              children: [
                const SizedBox(width: 10.0),
                Flexible(
                  child: Text('• ${definition.def ?? ''}',
                      style: textTheme.headlineSmall),
                ),
              ],
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabulary = _vocabulary;
    if (vocabulary == null) {
      if (isEnd) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/launcher/icon_tired.png'),
            Text('學完囉，返回上個頁面挑選其他的字彙表或馬上開始複習吧',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SelectableText(
                      vocabulary.title,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontFamilyFallback: const ['MOEDICT']),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 15),
                  InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () => _tryToPlayAudio(vocabulary),
                    child: const Icon(Icons.volume_up, size: 35),
                  ),
                ],
              ),
              Expanded(child: buildBody(context, vocabulary)),
            ],
          ),
        ),
      ),
    );
  }
}
