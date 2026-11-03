import 'package:oh_tai_gi/db/vocabulary.dart' as v;
import 'package:oh_tai_gi/db/vocabulary_list.dart' as vl;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String databaseName = 'OhTaiGi.db';

/// Schema history:
/// 1. Initial schema.
/// 2. Added `vocabulary.chinese`.
/// 3. Added indexes on the title columns; titles replace `hashCode` lookups,
///    because `String.hashCode` is not stable across Dart SDK versions.
const int databaseVersion = 3;

Future<void> _createV1(Database db) async {
  await db.execute('''
    create table ${vl.tableVocabularyList} (
      ${vl.columnUId} integer primary key autoincrement,
      ${vl.columnMId} text unique,
      ${vl.columnHashCode} integer not null,
      ${vl.columnList} text not null,
      ${vl.columnTitle} text not null,
      ${vl.columnCover} text not null,
      ${vl.columnProvider} text not null)
    ''');

  await db.execute('''
    create table ${v.tableVocabulary} (
      ${v.columnUId} integer primary key autoincrement,
      ${v.columnHashCode} integer not null,
      ${v.columnTitle} text not null,
      ${v.columnHeteronyms} text not null,
      ${v.columnLearnt} integer not null)
    ''');
}

Future<void> _upgradeToV2(Database db) async {
  await db.execute('''
    alter table ${v.tableVocabulary} add column ${v.columnChinese} text not null default ""
    ''');
}

Future<void> _upgradeToV3(Database db) async {
  await db.execute(
      'create index if not exists vocabulary_title on ${v.tableVocabulary} (${v.columnTitle})');
  await db.execute(
      'create index if not exists vocabulary_list_title on ${vl.tableVocabularyList} (${vl.columnTitle})');
}

/// Opens (creating or upgrading as needed) the app database at [path].
///
/// [factory] is only overridden by tests.
Future<Database> openOhTaiGiDatabase(String path,
    {DatabaseFactory? factory, int version = databaseVersion}) {
  return (factory ?? databaseFactory).openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (db, version) async {
        await _createV1(db);
        if (version >= 2) await _upgradeToV2(db);
        if (version >= 3) await _upgradeToV3(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2 && newVersion >= 2) await _upgradeToV2(db);
        if (oldVersion < 3 && newVersion >= 3) await _upgradeToV3(db);
      },
    ),
  );
}

class DBHolder {
  Database? db;
  Future<Database>? _opening;

  DBHolder._privateConstructor();

  static final DBHolder _instance = DBHolder._privateConstructor();

  factory DBHolder() => _instance;

  /// Closes the database; the next [initialize] opens it again.
  Future<void> close() async {
    final opened = db;
    db = null;
    _opening = null;
    await opened?.close();
  }

  /// Opens the database once; concurrent callers share the same future.
  Future<Database> initialize() async {
    final opened = db;
    if (opened != null) return opened;
    final opening = _opening ??= () async {
      final path = join(await getDatabasesPath(), databaseName);
      return db = await openOhTaiGiDatabase(path);
    }();
    try {
      return await opening;
    } catch (_) {
      // Let the next call try again instead of caching the failure.
      _opening = null;
      rethrow;
    }
  }
}
