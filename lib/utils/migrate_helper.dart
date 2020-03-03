
import 'dart:convert';

import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class MigrateHelper {
  static Future migrateVocabularyDB(bool withOldVer) async {
    VocabularyProvider vp = VocabularyProvider();
    await vp.open();
    List<Vocabulary> vs = [];
    String contents = await getFileData("assets/dict/dict-twblg-merge.json");
    String refTable = await getFileData("assets/dict/dict-ref.json");
    Map refs = json.decode(refTable)['a'];
    vs.insertAll(0, json.decode(contents).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList());
    if(vs.length > 0) {
      if(withOldVer) {
        List<Vocabulary> vss = await vp.getVocabularyList(limit: 100000, where: '$columnLearnt > ?', whereArgs: [0]);
        vs = await Future.wait(vs.map((vocabulary) async {
          Vocabulary v = vss.firstWhere(
            (learntVocabulary) {
              return learntVocabulary.title == vocabulary.title;
            }, 
            orElse: (){
              return null;
            }
          );
          if(v != null) vocabulary.learnt = v.learnt;
          return vocabulary;
        }));
      }
      vs = vs.map((vocabulary) {
        vocabulary.chinese = refs.containsKey(vocabulary.title)?refs[vocabulary.title]:"";
        return vocabulary;
      }).toList();
      await vp.deleteAll();
      vs = await vp.insertAll(vs);
    }
  }

  static Future migrateListDB() async {
    VocabularyListProvider vlp = VocabularyListProvider();
    await vlp.open();
    await vlp.deleteAll();
  }
}