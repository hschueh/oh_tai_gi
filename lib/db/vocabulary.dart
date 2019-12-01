import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

final String tableVocabulary = 'vocabulary';
final String columnUId = '_id';
final String columnHashCode = 'hashCode';
final String columnTitle = 'title';
final String columnHeteronyms = 'heteronyms';
final String columnLearnt = 'learnt';

final String columnTRS = 'trs';
final String columnAudioId = 'audio_id';
final String columnId = 'id';
final String columnReading = 'reading';
final String columnDefinitions = 'definitions';

final String columnType = 'type';
final String columnDefinition = 'def';
final String columnExample = 'exp';

int valueOf(dynamic obj) {
  if(obj is int)
    return obj;
  else if(obj is String)
    return int.parse(obj);
  else
    return 0;
}

class Heteronym {
  String trs;
  int aid;
  String reading;
  List<Definition> definitions;

  String toString() {
    return json.encode(toJson());
  }
  	
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      columnTRS: trs,
      columnAudioId: aid,
      columnReading: reading,
      columnDefinitions: json.encode(definitions)
    };
  }

  void clone(Heteronym target) {
    trs = target.trs;
    aid = target.aid;
    reading = target.reading;
    definitions = target.definitions;
  }
  
  Heteronym.fromString(String string) : this.fromJson(json.decode(string));

  Heteronym.fromJson(Map<String, dynamic> map) {
    trs = map[columnTRS];
    aid = map.containsKey(columnAudioId)?valueOf(map[columnAudioId]):valueOf(map[columnId]);
    reading = map[columnReading];
    definitions = (map[columnDefinitions] is String)?
      json.decode(map[columnDefinitions]).map<Definition>((item) => Definition.fromJson(item)).toList():
      map[columnDefinitions].map<Definition>((json) => Definition.fromJson(json)).toList();
  }
}

class Definition {
  String type;
  String def;
  String exp;

  String toString() {
    return json.encode(toJson());
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

  Definition.fromString(String string)  : this.fromJson(json.decode(string));

  Definition.fromJson(Map<String, dynamic> map) {
    type = map[columnType];
    def = map[columnDefinition];
    exp = map[columnExample];
  }
}

class Vocabulary {
  int id;
  int hashTitle;
  String title;
  List<Heteronym> heteronyms;
  int learnt;

  Vocabulary();

  String toString() {
    return json.encode(toJson());
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnLearnt: learnt,
      columnHashCode: hashTitle,
      columnHeteronyms: json.encode(heteronyms)
    };
    if (id != null) {
      map[columnUId] = id;
    }
    return map;
  }
  void clone(Vocabulary target) {
    id = target.id;
    title = target.title;
    hashTitle = target.hashTitle;
    learnt = target.learnt;
    heteronyms = target.heteronyms;
  }

  Vocabulary.fromString(String string) : this.fromJson(json.decode(string));

  Vocabulary.fromJson(Map<String, dynamic> map) {
    id = map[columnUId];
    title = map[columnTitle];
    hashTitle = title.hashCode;
    learnt = map.containsKey(columnLearnt)?map[columnLearnt]:0;
    heteronyms = (map[columnHeteronyms] is String)?
      json.decode(map[columnHeteronyms]).map<Heteronym>((item) => Heteronym.fromJson(item)).toList():
      map[columnHeteronyms].map<Heteronym>((json) => Heteronym.fromJson(json)).toList();
  }
}

class VocabularyProvider {
  Database db;

  VocabularyProvider._privateConstructor();

  static final VocabularyProvider _instance = VocabularyProvider._privateConstructor();

  factory VocabularyProvider(){
    return _instance;
  }

  Future open(String path) async {
    if(db == null) {
      db = await openDatabase(join(await getDatabasesPath(), path), version: 1,
          onCreate: (Database db, int version) async {
        await db.execute('''
          create table $tableVocabulary ( 
            $columnUId integer primary key autoincrement, 
            $columnHashCode integer not null,
            $columnTitle text not null,
            $columnHeteronyms text not null,
            $columnLearnt integer not null)
          ''');
      });
    }
    return;
  }

  Future<Vocabulary> insert(Vocabulary vocabulary) async {
    vocabulary.id = await db.insert(tableVocabulary, vocabulary.toJson());
    return vocabulary;
  }

  Future<List<dynamic>> insertAll(List<Vocabulary> vocabularyList) async {
    Batch batch = db.batch();
    for(int i = 0; i < vocabularyList.length; ++i)
      batch.insert(tableVocabulary, vocabularyList[i].toJson());
    List<dynamic> ret = await batch.commit(continueOnError: true);
    ret.asMap().forEach((index, value) => vocabularyList[index].id = value);
    return vocabularyList;
  }

  Future<Vocabulary> getVocabulary(int id) async {
    List<Map> maps = await db.query(tableVocabulary,
        where: '$columnUId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Vocabulary.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Vocabulary>> getVocabularyList({offset: 0, limit: 50, dynamic where, List<dynamic> whereArgs}) async {
    List<Map> maps = await db.query(tableVocabulary, limit: limit, offset: offset, where: where, whereArgs: whereArgs, orderBy: '$columnLearnt ASC');
    if (maps.length > 0) {
      return List.generate(maps.length, (i) {
        return Vocabulary.fromJson(maps[i]);
      });
    }
    return <Vocabulary>[];
  }

  Future<Vocabulary> getVocabularyWithTitle(String title) async {
    return await getVocabularyWithTitleHash(title.hashCode);
  }

  Future<Vocabulary> getVocabularyWithTitleHash(int titleHashCode) async {
    List<Map> maps = await db.query(tableVocabulary,
        where: '$columnHashCode = ?',
        whereArgs: [titleHashCode]);
    if (maps.length > 0) {
      return Vocabulary.fromJson(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableVocabulary, where: '$columnUId = ?', whereArgs: [id]);
  }

  Future<int> deleteWithHashTitle(int titleHashCode) async {
    return await db.delete(tableVocabulary, where: '$columnHashCode = ?', whereArgs: [titleHashCode]);
  }

  Future<int> update(Vocabulary vocabulary) async {
    return await db.update(tableVocabulary, vocabulary.toJson(),
        where: '$columnUId = ?', whereArgs: [vocabulary.id]);
  }


  Future<List<dynamic>> updateAll(List<Vocabulary> vocabularyList) async {
    Batch batch = db.batch();
    for(int i = 0; i < vocabularyList.length; ++i)
      batch.update(tableVocabulary, vocabularyList[i].toJson(), where: '$columnUId = ?', whereArgs: [vocabularyList[i].id]);
    List<dynamic> ret = await batch.commit(continueOnError: true);
    return ret;
  }

  Future close() async => db.close();
}