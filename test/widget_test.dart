import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:oh_tai_gi/main.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('oh_tai_gi_widget');
    DBHolder().db = await openOhTaiGiDatabase('${tempDir.path}/$databaseName',
        factory: databaseFactoryFfi);
    SharedPreferences.setMockInitialValues({});
    // Imports the bundled dictionary, like the first launch on a device.
    await OTGConfig.initialize();
  });

  tearDownAll(() async {
    await DBHolder().db?.close();
    DBHolder().db = null;
    await tempDir.delete(recursive: true);
  });

  testWidgets('shows the tabs and searches the dictionary', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const OhTaiGiApp(showAds: false));
      // Let the database queries of the first page finish.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    for (final destination in allDestinations) {
      expect(find.text(destination.title), findsWidgets);
    }
    // The random learning page shows a flash card.
    expect(find.text('記得了就往右滑，還沒記住往左滑'), findsOneWidget);

    // Search for a word.
    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pumpAndSettle();
    expect(find.text('輸入關鍵字尋找相關詞彙'), findsOneWidget);
    await tester.tap(find.byTooltip('搜尋'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.enterText(find.byType(TextField), '臺灣');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(find.text('找不到相關詞彙'), findsNothing);
    expect(find.textContaining('臺灣'), findsWidgets);
  });
}
