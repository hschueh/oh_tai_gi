import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerHolder {
  static AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";

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