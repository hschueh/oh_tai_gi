import 'dart:convert';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class MigrateHelper {
  /// Rebuilds the vocabulary table from the bundled dictionary.
  ///
  /// When [withOldVer] is true the learning progress (`learnt`) of the
  /// existing rows is carried over, matched by title.
  static Future<void> migrateVocabularyDB(bool withOldVer) async {
    final vp = VocabularyProvider();
    await vp.open();
    final contents = await getFileData('assets/dict/dict-twblg-merge.json');
    final refTable = await getFileData('assets/dict/dict-ref.json');
    final refs = (json.decode(refTable) as Map<String, dynamic>)['a']
        as Map<String, dynamic>;
    final vs = (json.decode(contents) as List)
        .map<Vocabulary>(
            (item) => Vocabulary.fromJson(item as Map<String, dynamic>))
        .toList();
    await rebuildVocabularyTable(vp, vs, refs, keepLearnt: withOldVer);
  }

  /// Replaces the vocabulary table with [vocabularies]. Split out of
  /// [migrateVocabularyDB] so it can be tested without Flutter assets.
  static Future<List<Vocabulary>> rebuildVocabularyTable(
      VocabularyProvider vp,
      List<Vocabulary> vocabularies,
      Map<String, dynamic> chineseRefs,
      {required bool keepLearnt}) async {
    if (vocabularies.isEmpty) return vocabularies;
    if (keepLearnt) {
      final learnt = await vp.getVocabularyList(
          limit: 1000000, where: '$columnLearnt > ?', whereArgs: [0]);
      final learntByTitle = {for (final v in learnt) v.title: v.learnt};
      for (final vocabulary in vocabularies) {
        final count = learntByTitle[vocabulary.title];
        if (count != null) vocabulary.learnt = count;
      }
    }
    for (final vocabulary in vocabularies) {
      final chinese = chineseRefs[vocabulary.title];
      vocabulary.chinese = chinese is String ? chinese : '';
    }
    // Delete and re-insert atomically so that the learning progress cannot
    // be lost if the app is killed half way through.
    await vp.db.transaction((txn) async {
      await txn.delete(tableVocabulary);
      final batch = txn.batch();
      for (final vocabulary in vocabularies) {
        vocabulary.id = null;
        batch.insert(tableVocabulary, vocabulary.toJson());
      }
      final ids = await batch.commit();
      for (var i = 0; i < ids.length; ++i) {
        final id = ids[i];
        if (id is int) vocabularies[i].id = id;
      }
    });
    return vocabularies;
  }

  static Future<void> migrateListDB() async {
    final vlp = VocabularyListProvider();
    await vlp.open();
    await vlp.deleteAll();
  }
}
