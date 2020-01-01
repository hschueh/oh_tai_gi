import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTGConfig extends InheritedWidget {
  static String get keyAutoPlayAudio => 'apa'; // 0: always. 1: only wifi. 2: never.
  static String get keyDBVer => 'dbver'; // 0: always. 1: only wifi. 2: never.
  static String get discoveryMain => 'dMain';
  static String get discoveryToggle => 'dToggle';
  static List<String> get valueAutoPlayAudio => ["永遠自動播放", "僅在wifi環境下", "永不"];

  static Map<String, dynamic> _config;
  static SharedPreferences _prefs;

  OTGConfig({ Widget child }) :super(child: child);

  static Future initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _config = {
      keyAutoPlayAudio: _prefs.get(keyAutoPlayAudio)??0,
      discoveryMain: _prefs.get(discoveryMain)??0,
      discoveryToggle: _prefs.get(discoveryToggle)??0,
      keyDBVer: _prefs.get(keyDBVer)??"0",
    };
  }

  dynamic get(String key, dynamic defaultValue) {
    if(_config == null || !_config.containsKey(key))
      return defaultValue;
    return _config[key];
  }

  static OTGConfig of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(OTGConfig);
  }

  void setKeyInt(String key, int value) async{
    _config[key] = value;
    await _prefs.setInt(key, value);
  }

  void setKeyString(String key, String value) async{
    _config[key] = value;
    await _prefs.setString(key, value);
  }

  void setKeyBool(String key, bool value) async{
    _config[key] = value;
    await _prefs.setBool(key, value);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}