import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

final String tableVocabularyList = 'vocabulary_list';
final String columnUId = '_id';
final String columnTitle = 'title';
final String columnCover = 'cover';
final String columnProvider = 'privider';
final String columnList = 'list';
final String columnHashCode = 'hashCode';

int valueOf(dynamic obj) {
  if(obj is int)
    return obj;
  else if(obj is String)
    return int.parse(obj);
  else
    return 0;
}

class VocabularyList {
  int id;
  int hashTitle;
  String title;
  String cover;
  String provider;
  List<String> list;

  VocabularyList();

  String toString() {
    return json.encode(toJson());
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{
      columnTitle: title,
      columnCover: cover,
      columnProvider: provider,
      columnList: json.encode(list),
      columnHashCode: hashTitle
    };
    if (id != null) {
      map[columnUId] = id;
    }
    return map;
  }
  void clone(VocabularyList target) {
    id = target.id;
    title = target.title;
    provider = target.provider;
    list = target.list;
    cover = target.cover;
    hashTitle = target.hashTitle;
  }

  VocabularyList.fromString(String string) : this.fromJson(json.decode(string));

  VocabularyList.fromJson(Map<String, dynamic> map) {
    id = map[columnUId];
    title = map[columnTitle];
    provider = map[columnProvider];
    cover = map[columnCover];
    hashTitle = title.hashCode;
    if(map[columnList] is List<String>) {
      list = map[columnList];
    } else if(map[columnList] is List) {
      list = new List<String>.from(map[columnList]);
    } else {
      list = new List<String>.from(json.decode(map[columnList]));
    }
  }
}

class VocabularyListProvider {
  Database db;

  VocabularyListProvider._privateConstructor();

  static final VocabularyListProvider _instance = VocabularyListProvider._privateConstructor();

  factory VocabularyListProvider(){
    return _instance;
  }

  Future open() async {
    if(db == null) {
      if(DBHolder().db == null) {
        await DBHolder().initialize();
      }
      db = DBHolder().db;
    }
    return;
  }

  Future<VocabularyList> insert(VocabularyList vocabularyList) async {
    vocabularyList.id = await db.insert(tableVocabularyList, vocabularyList.toJson());
    return vocabularyList;
  }

  Future<List<dynamic>> insertAll(List<VocabularyList> vocabularyLists) async {
    Batch batch = db.batch();
    for(int i = 0; i < vocabularyLists.length; ++i)
      batch.insert(tableVocabularyList, vocabularyLists[i].toJson());
    List<dynamic> ret = await batch.commit(continueOnError: true);
    ret.asMap().forEach((index, value) => vocabularyLists[index].id = value);
    return vocabularyLists;
  }

  Future<VocabularyList> getVocabulary(int id) async {
    List<Map> maps = await db.query(tableVocabularyList,
        where: '$columnUId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return VocabularyList.fromJson(maps.first);
    }
    return null;
  }

  Future<List<VocabularyList>> getVocabularyLists({offset: 0, limit: 50, dynamic where, List<dynamic> whereArgs}) async {
    List<Map> maps = await db.query(tableVocabularyList, limit: limit, offset: offset, where: where, whereArgs: whereArgs, orderBy: '$columnUId ASC');
    if (maps.length > 0) {
      return List.generate(maps.length, (i) {
        return VocabularyList.fromJson(maps[i]);
      });
    }
    return <VocabularyList>[];
  }

  Future<VocabularyList> getVocabularyListWithTitle(String title) async {
    return await getVocabularyListWithTitleHash(title.hashCode);
  }

  Future<VocabularyList> getVocabularyListWithTitleHash(int titleHashCode) async {
    List<Map> maps = await db.query(tableVocabularyList,
        where: '$columnHashCode = ?',
        whereArgs: [titleHashCode]);
    if (maps.length > 0) {
      return VocabularyList.fromJson(maps.first);
    }
    return null;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableVocabularyList, where: '$columnUId = ?', whereArgs: [id]);
  }

  Future<int> deleteWithHashTitle(int titleHashCode) async {
    return await db.delete(tableVocabularyList, where: '$columnHashCode = ?', whereArgs: [titleHashCode]);
  }

  Future<int> update(VocabularyList vocabulary) async {
    return await db.update(tableVocabularyList, vocabulary.toJson(),
        where: '$columnUId = ?', whereArgs: [vocabulary.id]);
  }


  Future<List<dynamic>> updateAll(List<VocabularyList> vocabularyList) async {
    Batch batch = db.batch();
    for(int i = 0; i < vocabularyList.length; ++i)
      batch.update(tableVocabularyList, vocabularyList[i].toJson(), where: '$columnUId = ?', whereArgs: [vocabularyList[i].id]);
    List<dynamic> ret = await batch.commit(continueOnError: true);
    return ret;
  }

  Future close() async => db.close();
}