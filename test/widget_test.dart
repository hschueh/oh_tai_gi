import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_tai_gi/db/db_holder.dart';
import 'package:oh_tai_gi/main.dart';
import 'package:oh_tai_gi/ui/component/big_card.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_foldable_card.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pumps until [finder] matches, letting real async work (sqflite on a
/// background isolate) run in between. Fails after [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for $finder');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

/// Runs the tab / search box animations (at most a few hundred ms).
///
/// `pumpAndSettle` cannot be used: offstage tabs may still show a loading
/// spinner, which never settles.
Future<void> pumpAnimations(WidgetTester tester) async {
  for (var i = 0; i < 10; ++i) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('oh_tai_gi_widget');
    DBHolder().db = await openOhTaiGiDatabase(
      '${tempDir.path}/$databaseName',
      factory: databaseFactoryFfi,
    );
    SharedPreferences.setMockInitialValues({});
    // Imports the bundled dictionary, like the first launch on a device.
    await OTGConfig.initialize();
  });

  tearDownAll(() async {
    await DBHolder().close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('shows the tabs and searches the dictionary', (tester) async {
    await tester.pumpWidget(const OhTaiGiApp(showAds: false));

    for (final destination in allDestinations) {
      expect(find.text(destination.title), findsWidgets);
    }
    // The random learning page loads a flash card from the database.
    await pumpUntilFound(
      tester,
      find.descendant(
        of: find.byType(BigCard),
        matching: find.byIcon(Icons.volume_up),
      ),
    );
    expect(find.text('記得了就往右滑，還沒記住往左滑'), findsOneWidget);

    // Search for a word.
    await tester.tap(find.byIcon(Icons.search).last);
    await pumpAnimations(tester);
    expect(find.text('輸入關鍵字尋找相關詞彙'), findsOneWidget);
    expect(find.byType(SmallVocabularyFoldableCard), findsNothing);
    await tester.tap(find.byTooltip('搜尋'));
    await pumpAnimations(tester);
    await tester.enterText(find.byType(TextField), '臺灣');

    final results = find.byType(SmallVocabularyFoldableCard);
    await pumpUntilFound(tester, results);
    expect(find.text('找不到相關詞彙'), findsNothing);
    // At least one result card has 臺灣 in its title.
    expect(
      find.descendant(
        of: results,
        matching: find.textContaining('臺灣', findRichText: true),
      ),
      findsWidgets,
    );
  });
}
