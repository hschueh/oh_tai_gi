
import 'package:oh_tai_gi/db/vocabulary.dart' as v;
import 'package:oh_tai_gi/db/vocabulary_list.dart' as vl;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHolder {
  Database db;

  DBHolder._privateConstructor();

  initialize() async {
    if(db == null) {
      db = await openDatabase(join(await getDatabasesPath(), "OhTaiGi.db"), version: 2,
          onCreate: (Database db, int version) async {
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
                ${v.columnLearnt} integer not null,
                ${v.columnChinese} text not null)
              ''');
          },
          onUpgrade: (Database db, int oldVersion, int newVersion) async {
            // we add chinese in version 2.
            if(oldVersion < 2)
              await db.execute('''
              alter table ${v.tableVocabulary} add column ${v.columnChinese} text default "";
              ''');
          }
      );
    }
  }

  static final DBHolder _instance = DBHolder._privateConstructor();

  factory DBHolder(){
    return _instance;
  }
}