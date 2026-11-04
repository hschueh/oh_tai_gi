import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

typedef OnVocabularyListTap = void Function(
    BuildContext context, VocabularyList list);

class SmallVocabularyListCard extends StatelessWidget {
  const SmallVocabularyListCard(this._vocabularyList, this.isNew, this._onTap,
      {super.key});

  final VocabularyList _vocabularyList;
  final OnVocabularyListTap _onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        splashColor: Colors.blue[200]!.withAlpha(30),
        onTap: () => _onTap(context, _vocabularyList),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  _vocabularyList.title,
                  style: textTheme.headlineSmall
                      ?.copyWith(fontFamilyFallback: const ['MOEDICT']),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(_vocabularyList.provider,
                    style: textTheme.titleMedium),
              ),
              if (isNew)
                const Align(
                  alignment: Alignment.topRight,
                  child: Icon(Icons.new_releases),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
