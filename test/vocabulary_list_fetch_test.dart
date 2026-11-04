import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';

VocabularyList _list(String title, List<String> words) => VocabularyList()
  ..title = title
  ..list = words;

Future<List<VocabularyList>> _fetch(http.Response response) =>
    VocabularyListProvider().fetchVocabularyLists(
        client: MockClient((request) async => response));

void main() {
  test('fetches over HTTPS', () async {
    Uri? requested;
    await VocabularyListProvider().fetchVocabularyLists(
        client: MockClient((request) async {
      requested = request.url;
      return http.Response('[]', 200);
    }));
    expect(requested?.scheme, 'https');
  });

  test('parses the bundled list file, which is the published format', () async {
    final bytes = File('assets/dict/dict-list.json').readAsBytesSync();
    final expected = json.decode(utf8.decode(bytes)) as List;

    final lists = await _fetch(http.Response.bytes(bytes, 200));

    expect(lists, hasLength(expected.length));
    expect(lists.first.title, expected.first['title']);
    expect(lists.first.provider, expected.first['privider']);
    expect(lists.first.list, expected.first['list']);
    expect(lists.first.id, isNull);
  });

  test('never takes the local row id from the file', () async {
    final lists = await _fetch(http.Response(
        json.encode([
          {'_id': 7, 'title': 'a', 'list': <String>[]}
        ]),
        200));
    expect(lists.single.id, isNull);
  });

  test('returns nothing when the file is unavailable or malformed', () async {
    expect(await _fetch(http.Response('[]', 404)), isEmpty);
    expect(await _fetch(http.Response('not json', 200)), isEmpty);
    expect(await _fetch(http.Response('{"title": "a"}', 200)), isEmpty);
    expect(await _fetch(http.Response('[{"title": 1}]', 200)), isEmpty);
  });

  test('a corrected list is not inserted as a second copy', () {
    final stored = [
      _list('a', ['one'])
    ];
    final fetched = [
      _list('a', ['one', 'two']),
      _list('b', ['three']),
      _list('b', ['three']),
    ];

    final toInsert = vocabularyListsToInsert(stored, fetched);

    expect(toInsert.map((list) => list.title), ['b']);
  });
}
