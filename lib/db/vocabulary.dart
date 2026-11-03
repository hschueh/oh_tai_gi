import 'dart:convert';

import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:sqflite/sqflite.dart';

const String tableVocabulary = 'vocabulary';
const String columnUId = '_id';
const String columnHashCode = 'hashCode';
const String columnTitle = 'title';
const String columnHeteronyms = 'heteronyms';
const String columnLearnt = 'learnt';
const String columnChinese = 'chinese';

const String columnTRS = 'trs';
const String columnAudioId = 'audio_id';
const String columnId = 'id';
const String columnReading = 'reading';
const String columnDefinitions = 'definitions';

const String columnType = 'type';
const String columnDefinition = 'def';
const String columnExample = 'exp';

int valueOf(Object? obj) {
  if (obj is int) return obj;
  if (obj is String) return int.tryParse(obj) ?? 0;
  return 0;
}

/// Decodes [value] if it is a JSON string, otherwise returns it as is.
List<dynamic> _decodeList(Object? value) {
  if (value is String) return json.decode(value) as List<dynamic>;
  if (value is List) return value;
  return const [];
}

class Heteronym {
  String? trs;
  int aid = 0;
  String? reading;
  List<Definition> definitions = [];

  Heteronym();

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      columnTRS: trs,
      columnAudioId: aid,
      columnReading: reading,
      columnDefinitions: json.encode(definitions),
    };
  }

  void clone(Heteronym target) {
    trs = target.trs;
    aid = target.aid;
    reading = target.reading;
    definitions = target.definitions;
  }

  Heteronym.fromString(String string)
      : this.fromJson(json.decode(string) as Map<String, dynamic>);

  Heteronym.fromJson(Map<String, dynamic> map) {
    trs = map[columnTRS] as String?;
    aid = map.containsKey(columnAudioId)
        ? valueOf(map[columnAudioId])
        : valueOf(map[columnId]);
    reading = map[columnReading] as String?;
    definitions = _decodeList(map[columnDefinitions])
        .map<Definition>(
            (item) => Definition.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class Definition {
  String? type;
  String? def;
  String? exp;

  Definition();

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      columnType: type,
      columnDefinition: def,
      columnExample: exp,
    };
  }

  void clone(Definition target) {
    type = target.type;
    def = target.def;
    exp = target.exp;
  }

  Definition.fromString(String string)
      : this.fromJson(json.decode(string) as Map<String, dynamic>);

  Definition.fromJson(Map<String, dynamic> map) {
    type = map[columnType] as String?;
    def = map[columnDefinition] as String?;
    final example = map[columnExample];
    exp = example is String ? example : null;
  }
}

class Vocabulary {
  int? id;
  int hashTitle = 0;
  String title = '';
  String chinese = '';
  List<Heteronym> heteronyms = [];
  int learnt = 0;

  Vocabulary();

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      columnTitle: title,
      columnLearnt: learnt,
      columnHashCode: hashTitle,
      columnChinese: chinese,
      columnHeteronyms: json.encode(heteronyms),
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
    chinese = target.chinese;
  }

  Vocabulary.fromString(String string)
      : this.fromJson(json.decode(string) as Map<String, dynamic>);

  Vocabulary.fromJson(Map<String, dynamic> map) {
    id = map[columnUId] as int?;
    title = map[columnTitle] as String? ?? '';
    hashTitle = title.hashCode;
    learnt = valueOf(map[columnLearnt]);
    chinese = map[columnChinese] as String? ?? '';
    heteronyms = _decodeList(map[columnHeteronyms])
        .map<Heteronym>(
            (item) => Heteronym.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class VocabularyProvider {
  Database? _db;

  VocabularyProvider._privateConstructor();

  static final VocabularyProvider _instance =
      VocabularyProvider._privateConstructor();

  factory VocabularyProvider() => _instance;

  Database get db {
    final db = _db;
    if (db == null) {
      throw StateError('VocabularyProvider.open() must be awaited first.');
    }
    return db;
  }

  Future<void> open() async {
    _db ??= await DBHolder().initialize();
  }

  Future<Vocabulary> insert(Vocabulary vocabulary) async {
    vocabulary.id = await db.insert(tableVocabulary, vocabulary.toJson());
    return vocabulary;
  }

  Future<List<Vocabulary>> insertAll(List<Vocabulary> vocabularyList) async {
    final batch = db.batch();
    for (final vocabulary in vocabularyList) {
      batch.insert(tableVocabulary, vocabulary.toJson());
    }
    final ret = await batch.commit(continueOnError: true);
    for (var i = 0; i < ret.length; ++i) {
      final value = ret[i];
      if (value is int) vocabularyList[i].id = value;
    }
    return vocabularyList;
  }

  Future<Vocabulary?> getVocabulary(int id) async {
    final maps = await db
        .query(tableVocabulary, where: '$columnUId = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Vocabulary.fromJson(maps.first) : null;
  }

  Future<List<Vocabulary>> getVocabularyList({
    int offset = 0,
    int limit = 50,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final maps = await db.query(tableVocabulary,
        limit: limit,
        offset: offset,
        where: where,
        whereArgs: whereArgs,
        orderBy: '$columnLearnt ASC');
    return maps.map(Vocabulary.fromJson).toList();
  }

  Future<List<Vocabulary>> searchVocabularyWithKeyword(
      String keyword, List<String> columns,
      {int offset = 0, int limit = 50}) {
    final where = columns.map((column) => '$column LIKE ?').join(' OR ');
    return getVocabularyList(
      offset: offset,
      limit: limit,
      where: where,
      whereArgs: columns.map((_) => '%$keyword%').toList(growable: false),
    );
  }

  /// Looks a vocabulary up by its title.
  ///
  /// Older versions of the app looked vocabularies up by `title.hashCode`,
  /// which is not guaranteed to be stable across Dart SDK versions, so the
  /// title itself (indexed since DB version 3) is used instead.
  Future<Vocabulary?> getVocabularyWithTitle(String title) async {
    final maps = await db.query(tableVocabulary,
        where: '$columnTitle = ?', whereArgs: [title], limit: 1);
    return maps.isNotEmpty ? Vocabulary.fromJson(maps.first) : null;
  }

  /// Returns the vocabularies whose titles are in [titles], keeping the order
  /// of [titles] and skipping titles that are not in the dictionary.
  Future<List<Vocabulary>> getVocabulariesWithTitles(
      List<String> titles) async {
    if (titles.isEmpty) return [];
    final byTitle = <String, Vocabulary>{};
    // SQLite limits the number of bound variables, so query in chunks.
    const chunkSize = 500;
    for (var start = 0; start < titles.length; start += chunkSize) {
      final chunk = titles.sublist(
          start, (start + chunkSize).clamp(0, titles.length).toInt());
      final placeholders = List.filled(chunk.length, '?').join(',');
      final maps = await db.query(tableVocabulary,
          where: '$columnTitle IN ($placeholders)', whereArgs: chunk);
      for (final map in maps) {
        final v = Vocabulary.fromJson(map);
        byTitle.putIfAbsent(v.title, () => v);
      }
    }
    return [
      for (final title in titles)
        if (byTitle[title] != null) byTitle[title]!,
    ];
  }

  Future<int> delete(int id) {
    return db.delete(tableVocabulary, where: '$columnUId = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() => db.delete(tableVocabulary);

  Future<int> update(Vocabulary vocabulary) {
    return db.update(tableVocabulary, vocabulary.toJson(),
        where: '$columnUId = ?', whereArgs: [vocabulary.id]);
  }

  Future<List<Object?>> updateAll(List<Vocabulary> vocabularyList) {
    final batch = db.batch();
    for (final vocabulary in vocabularyList) {
      batch.update(tableVocabulary, vocabulary.toJson(),
          where: '$columnUId = ?', whereArgs: [vocabulary.id]);
    }
    return batch.commit(continueOnError: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
