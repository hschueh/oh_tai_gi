import 'package:sqflite/sqflite.dart';
import 'dart:convert';

final String tableVocabulary = 'vocabulary';
final String columnUId = '_id';
final String columnTitle = 'title';
final String columnHeteronyms = 'heteronyms';
final String columnLearnt = 'learnt';

final String columnTRS = 'trs';
final String columnAudioId = 'aid';
final String columnId = 'id';
final String columnReading = 'reading';
final String columnDefinitions = 'definitions';

final String columnType = 'type';
final String columnDefinition = 'def';
final String columnExample = 'exp';

class Heteronym {
  String trs;
  int aid;
  String reading;
  List<Definition> definitions;

  String toString() {
    return toJson().toString();
  }
  	
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      columnTRS: trs,
      columnAudioId: aid,
      columnReading: reading,
      columnDefinitions: definitions.toString()
    };
  }

  void clone(Heteronym target) {
    trs = target.trs;
    aid = target.aid;
    reading = target.reading;
    definitions = target.definitions;
  }
  
  Heteronym.fromString(String string) {
    Heteronym h = Heteronym.fromJson(json.decode(string));
    clone(h);
  }

  Heteronym.fromJson(Map<String, dynamic> map) {
    trs = map[columnTRS];
    aid = int.parse(map.containsKey(columnAudioId)?map[columnAudioId]:map[columnId]);
    reading = map[columnReading];
    definitions = (map[columnDefinitions] is String)?
      json.decode(map[columnDefinitions]).map<Definition>((string) => Definition.fromString(string)).toList():
      map[columnDefinitions].map<Definition>((json) => Definition.fromJson(json)).toList();
  }
}

class Definition {
  String type;
  String def;
  String exp;

  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      columnType: type,
      columnDefinition: def,
      columnExample: exp
    };
  }

  void clone(Definition target) {
    type = target.type;
    def = target.def;
    exp = target.exp;
  }

  Definition.fromString(String string) {
    Definition d = new Definition.fromJson(json.decode(string));
    clone(d);
  }

  Definition.fromJson(Map<String, dynamic> map) {
    type = map[columnType];
    def = map[columnDefinition];
    exp = map[columnExample];
  }
}

class Vocabulary {
  int id;
  String title;
  List<Heteronym> heteronyms;
  int learnt;

  Vocabulary();

  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnLearnt: learnt
    };
    if (id != null) {
      map[columnUId] = id;
    }
    return map;
  }
  void clone(Vocabulary target) {
    id = target.id;
    title = target.title;
    learnt = target.learnt;
    heteronyms = target.heteronyms;
  }

  Vocabulary.fromString(String string) {
    Vocabulary v = new Vocabulary.fromJson(json.decode(string));
    clone(v);
  }

  Vocabulary.fromJson(Map<String, dynamic> map) {
    id = map[columnUId];
    title = map[columnTitle];
    learnt = map.containsKey(columnLearnt)?map[columnLearnt]:0;
    heteronyms = (map[columnHeteronyms] is String)?
      json.decode(map[columnHeteronyms]).map<Heteronym>((string) => Heteronym.fromString(string)).toList():
      map[columnHeteronyms].map<Heteronym>((json) => Heteronym.fromJson(json)).toList();
  }
}

class VocabularyProvider {
  Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
        create table $tableVocabulary ( 
          $columnUId integer primary key autoincrement, 
          $columnTitle text not null,
          $columnLearnt integer not null)
        ''');
    });
  }

  Future<Vocabulary> insert(Vocabulary vocabulary) async {
    vocabulary.id = await db.insert(tableVocabulary, vocabulary.toJson());
    return vocabulary;
  }

  Future<Vocabulary> getVocabulary(int id) async {
    List<Map> maps = await db.query(tableVocabulary,
        columns: [columnUId, columnLearnt, columnTitle],
        where: '$columnUId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Vocabulary.fromJson(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableVocabulary, where: '$columnUId = ?', whereArgs: [id]);
  }

  Future<int> update(Vocabulary vocabulary) async {
    return await db.update(tableVocabulary, vocabulary.toJson(),
        where: '$columnUId = ?', whereArgs: [vocabulary.id]);
  }

  Future close() async => db.close();
}