import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class AudioPlayerHolder {
  static AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY)
    ..onPlayerCompletion.listen((event) {
      finished = true;
    })
    ..onPlayerError.listen((event) {
      finished = true;
    });
  static AudioCache localPlayer = AudioCache();
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";
  static bool finished = true;

  static Future<void> playLocal(String file) async {
    localPlayer.play("audio/$file");
  }

  static Future<void> tryToPlayAudio(int originalAid) async {
    if(await getConnectivityResult() < 0)
      return;
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.play("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
  }
  static Future<void> tryToPlayAudioReturnOnCompletion(int originalAid) async {
    if(await getConnectivityResult() < 0)
      return;
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.play("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    finished = false;
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
    while(!finished) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    return;
  }

  // Not working properly. Will cause audio overlapped each other.
  static Future<void> prepareAudio(int originalAid) async {
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.setUrl("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
  }
}