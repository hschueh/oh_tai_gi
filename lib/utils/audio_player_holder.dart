import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';

class AudioPlayerHolder {
  static AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static AudioCache localPlayer = AudioCache();
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";

  static Future<void> playLocal(String file) async {
    localPlayer.play("audio/$file");
  }

  static Future<void> tryToPlayAudio(int originalAid) async {
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.play("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
  }

  // Not working properly. Will cause audio overlapped each other.
  static Future<void> prepareAudio(int originalAid) async {
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.setUrl("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
  }
}