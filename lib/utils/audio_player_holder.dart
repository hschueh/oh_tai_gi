import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerHolder extends InheritedWidget {

  final AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  static String prefAudioFormat = (Platform.isIOS)?"mp3":"ogg";

  AudioPlayerHolder({
    Widget child
  }) :super(child: child);

  static AudioPlayerHolder of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(AudioPlayerHolder);
  }

  Future<void> tryToPlayAudio(int originalAid) async {
    String aid = originalAid.toString().padLeft(5, '0');
    int result = await audioPlayer.play("http://t.moedict.tw/$aid.$prefAudioFormat", isLocal: false);
    print("Play http://t.moedict.tw/$aid.$prefAudioFormat: $result");
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}