import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:sqflite/sqflite.dart';

const String tableVocabularyList = 'vocabulary_list';
const String columnUId = '_id';
const String columnMId = 'mongoId';
const String columnTitle = 'title';
const String columnCover = 'cover';
// Misspelled in the original schema; kept for compatibility.
const String columnProvider = 'privider';
const String columnList = 'list';
const String columnHashCode = 'hashCode';

/// The vocabulary lists are the JSON file in this repo, served over HTTPS, so
/// new lists can be published without releasing the app or running a server.
const String vocabularyListUrl =
    'https://raw.githubusercontent.com/hschueh/oh_tai_gi/master/assets/dict/dict-list.json';

class VocabularyList {
  int? id;
  int hashTitle = 0;
  String? mid;
  String title = '';
  String cover = '';
  String provider = '';
  List<String> list = [];

  VocabularyList();

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      columnTitle: title,
      columnCover: cover,
      columnProvider: provider,
      columnList: json.encode(list),
      columnHashCode: hashTitle,
    };
    if (id != null) {
      map[columnUId] = id;
    }
    if (mid != null) {
      map[columnMId] = mid;
    }
    return map;
  }

  void clone(VocabularyList target) {
    id = target.id;
    mid = target.mid;
    title = target.title;
    provider = target.provider;
    list = target.list;
    cover = target.cover;
    hashTitle = target.hashTitle;
  }

  VocabularyList.fromString(String string)
      : this.fromJson(json.decode(string) as Map<String, dynamic>);

  VocabularyList.fromJson(Map<String, dynamic> map) {
    final uid = map[columnUId];
    id = uid is int ? uid : null;
    mid = map[columnMId]?.toString();
    title = map[columnTitle] as String? ?? '';
    provider = map[columnProvider] as String? ?? '';
    cover = map[columnCover] as String? ?? '';
    hashTitle = title.hashCode;
    final rawList = map[columnList];
    if (rawList is List) {
      list = List<String>.from(rawList);
    } else if (rawList is String) {
      list = List<String>.from(json.decode(rawList) as List);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyList &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          listEquals(list, other.list);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(list));
}

/// The [fetched] lists that aren't stored yet. Lists are matched by title, so
/// correcting a published list doesn't add a second copy of it.
List<VocabularyList> vocabularyListsToInsert(
    List<VocabularyList> stored, List<VocabularyList> fetched) {
  final titles = stored.map((list) => list.title).toSet();
  return fetched.where((list) => titles.add(list.title)).toList();
}

class VocabularyListProvider {
  VocabularyListProvider._privateConstructor();

  static final VocabularyListProvider _instance =
      VocabularyListProvider._privateConstructor();

  factory VocabularyListProvider() => _instance;

  /// The database shared by all providers, see [DBHolder].
  Database get db {
    final db = DBHolder().db;
    if (db == null) {
      throw StateError('VocabularyListProvider.open() must be awaited first.');
    }
    return db;
  }

  Future<void> open() => DBHolder().initialize();

  Future<VocabularyList> insert(VocabularyList vocabularyList) async {
    vocabularyList.id =
        await db.insert(tableVocabularyList, vocabularyList.toJson());
    return vocabularyList;
  }

  Future<List<VocabularyList>> insertAll(
      List<VocabularyList> vocabularyLists) async {
    final batch = db.batch();
    for (final vocabularyList in vocabularyLists) {
      batch.insert(tableVocabularyList, vocabularyList.toJson());
    }
    final ret = await batch.commit(continueOnError: true);
    for (var i = 0; i < ret.length; ++i) {
      final value = ret[i];
      if (value is int) vocabularyLists[i].id = value;
    }
    return vocabularyLists;
  }

  Future<VocabularyList?> getVocabulary(int id) async {
    final maps = await db
        .query(tableVocabularyList, where: '$columnUId = ?', whereArgs: [id]);
    return maps.isNotEmpty ? VocabularyList.fromJson(maps.first) : null;
  }

  Future<List<VocabularyList>> getVocabularyLists({
    int offset = 0,
    int limit = 50,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final maps = await db.query(tableVocabularyList,
        limit: limit,
        offset: offset,
        where: where,
        whereArgs: whereArgs,
        orderBy: '$columnUId DESC');
    return maps.map(VocabularyList.fromJson).toList();
  }

  /// Fetches every published vocabulary list. Returns an empty list when they
  /// cannot be fetched, so callers can fall back to the bundled
  /// `assets/dict/dict-list.json`.
  Future<List<VocabularyList>> fetchVocabularyLists(
      {http.Client? client}) async {
    final uri = Uri.parse(vocabularyListUrl);
    try {
      final response = await (client?.get(uri) ?? http.get(uri))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final decoded = json.decode(utf8.decode(response.bodyBytes)) as List;
      return decoded.map<VocabularyList>((item) {
        // The local row id is assigned on insert, never taken from the file.
        final map = Map<String, dynamic>.from(item as Map)..remove(columnUId);
        return VocabularyList.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch vocabulary lists from $uri: $e');
      return [];
    }
  }

  Future<VocabularyList?> getVocabularyListWithTitle(String title) async {
    final maps = await db.query(tableVocabularyList,
        where: '$columnTitle = ?', whereArgs: [title], limit: 1);
    return maps.isNotEmpty ? VocabularyList.fromJson(maps.first) : null;
  }

  Future<int> delete(int id) {
    return db
        .delete(tableVocabularyList, where: '$columnUId = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() => db.delete(tableVocabularyList);

  Future<int> update(VocabularyList vocabulary) {
    return db.update(tableVocabularyList, vocabulary.toJson(),
        where: '$columnUId = ?', whereArgs: [vocabulary.id]);
  }

  Future<List<Object?>> updateAll(List<VocabularyList> vocabularyList) {
    final batch = db.batch();
    for (final item in vocabularyList) {
      batch.update(tableVocabularyList, item.toJson(),
          where: '$columnUId = ?', whereArgs: [item.id]);
    }
    return batch.commit(continueOnError: true);
  }

  /// Closes the database shared by all providers.
  Future<void> close() => DBHolder().close();
}
