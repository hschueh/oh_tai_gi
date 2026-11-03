import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart' show VocabularyListProvider;
import 'package:oh_tai_gi/utils/migrate_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Creates a database exactly like app version 1.0.21 (schema version 2) did,
/// with `hashCode` values that do NOT match the current SDK's
/// `String.hashCode`, to simulate a hash function change between Dart SDKs.
Future<void> createLegacyV2Database(String path) async {
  final db = await databaseFactoryFfi.openDatabase(path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            create table vocabulary_list (
              _id integer primary key autoincrement,
              mongoId text unique,
              hashCode integer not null,
              list text not null,
              title text not null,
              cover text not null,
              privider text not null)
            ''');
          await db.execute('''
            create table vocabulary (
              _id integer primary key autoincrement,
              hashCode integer not null,
              title text not null,
              heteronyms text not null,
              learnt integer not null,
              chinese text not null)
            ''');
        },
      ));
  final heteronyms = json.encode([
    {
      'trs': 'tsit',
      'audio_id': 1,
      'reading': '',
      'definitions': json.encode([
        {'type': '數', 'def': '數目', 'exp': null}
      ]),
    }
  ]);
  for (final (i, title) in ['一', '二', '三'].indexed) {
    await db.insert('vocabulary', {
      'hashCode': 12345 + i, // bogus legacy hash
      'title': title,
      'heteronyms': heteronyms,
      'learnt': i, // 一: 0, 二: 1, 三: 2
      'chinese': '',
    });
  }
  await db.insert('vocabulary_list', {
    'mongoId': 'abc',
    'hashCode': 999, // bogus legacy hash
    'list': json.encode(['三', '不存在', '一']),
    'title': '數字',
    'cover': '',
    'privider': 'O̍h Tâi Gí',
  });
  await db.close();
}

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('oh_tai_gi_test');
    dbPath = '${tempDir.path}/$databaseName';
    await createLegacyV2Database(dbPath);
    DBHolder().db =
        await openOhTaiGiDatabase(dbPath, factory: databaseFactoryFfi);
    await VocabularyProvider().open();
    await VocabularyListProvider().open();
  });

  tearDown(() async {
    await VocabularyProvider().close();
    await VocabularyListProvider().close();
    DBHolder().db = null;
    await tempDir.delete(recursive: true);
  });

  test('upgrades schema 2 to 3 and adds the title indexes', () async {
    final db = DBHolder().db!;
    expect(await db.getVersion(), 3);
    final indexes = await db.rawQuery(
        "select name from sqlite_master where type = 'index' and name like '%title'");
    expect(indexes.map((row) => row['name']),
        containsAll(['vocabulary_title', 'vocabulary_list_title']));
  });

  test('keeps learning progress after the upgrade', () async {
    final learnt = await VocabularyProvider()
        .getVocabularyList(where: '$columnLearnt > ?', whereArgs: [0]);
    expect({for (final v in learnt) v.title: v.learnt}, {'二': 1, '三': 2});
  });

  test('finds vocabularies by title even when the stored hash differs',
      () async {
    final v = await VocabularyProvider().getVocabularyWithTitle('三');
    expect(v, isNotNull);
    expect(v!.learnt, 2);
    expect(v.heteronyms.single.trs, 'tsit');
    expect(v.heteronyms.single.definitions.single.def, '數目');

    final list =
        await VocabularyListProvider().getVocabularyListWithTitle('數字');
    expect(list, isNotNull);
    final words =
        await VocabularyProvider().getVocabulariesWithTitles(list!.list);
    // Keeps the list order and skips titles missing from the dictionary.
    expect(words.map((v) => v.title), ['三', '一']);
  });

  test('rebuilding the dictionary keeps learning progress', () async {
    final vp = VocabularyProvider();
    final fresh = ['一', '二', '三', '四'].map((title) {
      return Vocabulary.fromJson({
        columnTitle: title,
        columnHeteronyms: <Map<String, dynamic>>[],
      });
    }).toList();
    await MigrateHelper.rebuildVocabularyTable(vp, fresh, {'四': '四'},
        keepLearnt: true);

    final all = await vp.getVocabularyList(limit: 100);
    expect({for (final v in all) v.title: v.learnt},
        {'一': 0, '二': 1, '三': 2, '四': 0});
    expect((await vp.getVocabularyWithTitle('四'))!.chinese, '四');
  });

  test('a fresh install creates the latest schema', () async {
    final path = '${tempDir.path}/fresh.db';
    final db = await openOhTaiGiDatabase(path, factory: databaseFactoryFfi);
    expect(await db.getVersion(), databaseVersion);
    final columns = await db.rawQuery('pragma table_info(vocabulary)');
    expect(columns.map((c) => c['name']), contains(columnChinese));
    await db.close();
  });
}
