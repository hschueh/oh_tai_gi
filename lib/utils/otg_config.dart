import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/utils/migrate_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTGConfig {
  static const String dbVersion = '20200303';
  static const String listVersion = '20200125';
  static const String keyAutoPlayAudio = 'apa'; // 0: always. 1: only wifi. 2: never.
  static const String keyPlayAudioInGame = 'paig'; // 0: no. 1: yes.
  static const String keyDBVer = 'dbver'; // String, if != dbVersion, the db will be update.
  static const String keyListVer = 'listver'; // String, if != listVersion, the list will be update.
  static const String discoveryMain = 'dMain';
  static const String discoveryToggle = 'dToggle';
  static const List<String> valueAutoPlayAudio = ['永遠自動播放', '僅在wifi環境下', '永不'];
  static const List<String> valuePlayAudioInGame = ['不播放語音', '播放(較簡單)'];

  static final Map<String, Object> _config = {};
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _config
      ..[keyAutoPlayAudio] = prefs.getInt(keyAutoPlayAudio) ?? 0
      ..[keyPlayAudioInGame] = prefs.getInt(keyPlayAudioInGame) ?? 1
      ..[discoveryMain] = prefs.getInt(discoveryMain) ?? 0
      ..[discoveryToggle] = prefs.getInt(discoveryToggle) ?? 0
      ..[keyDBVer] = prefs.getString(keyDBVer) ?? '0'
      ..[keyListVer] = prefs.getString(keyListVer) ?? '0';

    final vp = VocabularyProvider();
    await vp.open();

    if (_config[keyDBVer] != dbVersion) {
      await MigrateHelper.migrateVocabularyDB(_config[keyDBVer] != '0');
      await setKeyString(keyDBVer, dbVersion);
    }

    if (_config[keyListVer] != listVersion) {
      await MigrateHelper.migrateListDB();
      await setKeyString(keyListVer, listVersion);
    }
  }

  static T get<T extends Object>(String key, T defaultValue) {
    final value = _config[key];
    return value is T ? value : defaultValue;
  }

  static Future<void> setKeyInt(String key, int value) async {
    _config[key] = value;
    await _prefs?.setInt(key, value);
  }

  static Future<void> setKeyString(String key, String value) async {
    _config[key] = value;
    await _prefs?.setString(key, value);
  }

  static Future<void> setKeyBool(String key, bool value) async {
    _config[key] = value;
    await _prefs?.setBool(key, value);
  }
}
