import 'package:flutter/material.dart';
import 'package:oh_tai_gi/utils/migrate_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTGConfig {
  static String get dbVersion => '20200302';
  static String get listVersion => '20200125';
  static String get keyAutoPlayAudio => 'apa'; // 0: always. 1: only wifi. 2: never.
  static String get keyPlayAudioInGame => 'paig'; // 0: no. 1: yes.
  static String get keyDBVer => 'dbver'; // String, if != dbVersion, the db will be update.
  static String get keyListVer => 'listver'; // String, if != listVersion, the list will be update.
  static String get discoveryMain => 'dMain';
  static String get discoveryToggle => 'dToggle';
  static List<String> get valueAutoPlayAudio => ["永遠自動播放", "僅在wifi環境下", "永不"];
  static List<String> get valuePlayAudioInGame => ["不播放語音", "播放(較簡單)"];

  static Map<String, dynamic> _config;
  static SharedPreferences _prefs;

  static Future initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _config = {
      keyAutoPlayAudio: _prefs.get(keyAutoPlayAudio)??0,
      keyPlayAudioInGame: _prefs.get(keyPlayAudioInGame)??1,
      discoveryMain: _prefs.get(discoveryMain)??0,
      discoveryToggle: _prefs.get(discoveryToggle)??0,
      keyDBVer: _prefs.get(keyDBVer)??"0",
      keyListVer: _prefs.get(keyListVer)??"0",
    };

    if(_config[keyDBVer] != dbVersion) {
      await MigrateHelper.migrateVocabularyDB(_config[keyDBVer] != "0");
      setKeyString(keyDBVer, dbVersion);
    }

    if(_config[keyListVer] != listVersion) {
      await MigrateHelper.migrateListDB();
      setKeyString(keyListVer, listVersion);
    }
  }

  static dynamic get(String key, dynamic defaultValue) {
    if(_config == null || !_config.containsKey(key))
      return defaultValue;
    return _config[key];
  }

  static OTGConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType(aspect: OTGConfig);
  }

  static void setKeyInt(String key, int value) async{
    _config[key] = value;
    await _prefs.setInt(key, value);
  }

  static void setKeyString(String key, String value) async{
    _config[key] = value;
    await _prefs.setString(key, value);
  }

  static void setKeyBool(String key, bool value) async{
    _config[key] = value;
    await _prefs.setBool(key, value);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}