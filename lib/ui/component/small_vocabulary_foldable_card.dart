import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/audio_player_holder.dart';

class SmallVocabularyFoldableCard extends StatefulWidget {
  const SmallVocabularyFoldableCard(this.vocabulary,
      {super.key, this.foldable = false});

  final Vocabulary vocabulary;
  final bool foldable;

  @override
  State<SmallVocabularyFoldableCard> createState() =>
      _SmallVocabularyFoldableCardState();
}

class _SmallVocabularyFoldableCardState
    extends State<SmallVocabularyFoldableCard> {
  /// Maximum number of lines shown while folded.
  static const int _foldedLines = 4;

  late bool _folded = widget.foldable;

  Widget buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[];
    var needEllipsis = false;
    outer:
    for (final heteronym in widget.vocabulary.heteronyms) {
      if (_folded && children.length >= _foldedLines) {
        needEllipsis = true;
        break;
      }
      children.add(SelectableText(
        heteronym.trs ?? '',
        style: textTheme.titleMedium,
        maxLines: 1,
      ));
      for (final definition in heteronym.definitions) {
        if (_folded && children.length >= _foldedLines) {
          needEllipsis = true;
          break outer;
        }
        children.add(Row(
          children: [
            const SizedBox(width: 5.0),
            Flexible(
              child: Text('• ${definition.def ?? ''}',
                  style: textTheme.bodyMedium),
            ),
          ],
        ));
      }
    }
    if (needEllipsis) {
      children.add(Text(
        '點開看閣較濟...',
        style: textTheme.bodyLarge?.copyWith(color: Colors.blue[200]),
      ));
    }
    return Flexible(
      flex: 7,
      fit: FlexFit.tight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _tryToPlayAudio(Vocabulary vocabulary) async {
    for (final heteronym in vocabulary.heteronyms) {
      await AudioPlayerHolder.tryToPlayAudioReturnOnCompletion(heteronym.aid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.foldable) setState(() => _folded = !_folded);
      },
      child: Card(
        margin: const EdgeInsets.all(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  fit: FlexFit.tight,
                  child: SelectableText(
                    widget.vocabulary.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontFamilyFallback: const ['MOEDICT']),
                    maxLines: 1,
                  ),
                ),
                Flexible(
                  flex: 1,
                  fit: FlexFit.tight,
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () => _tryToPlayAudio(widget.vocabulary),
                    child: const Icon(Icons.volume_up, size: 25),
                  ),
                ),
                buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
