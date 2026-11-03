import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class AudioPlayerHolder {
  static final AudioPlayer audioPlayer = AudioPlayer();
  static final AudioPlayer _effectPlayer = AudioPlayer();
  static String prefAudioFormat = Platform.isIOS ? 'mp3' : 'ogg';

  static String _audioUrl(int aid) =>
      'http://t.moedict.tw/${aid.toString().padLeft(5, '0')}.$prefAudioFormat';

  /// Plays a sound effect from `assets/audio/`.
  static Future<void> playLocal(String file) async {
    try {
      await _effectPlayer.play(AssetSource('audio/$file'));
    } catch (e) {
      debugPrint('Failed to play $file: $e');
    }
  }

  static Future<void> tryToPlayAudio(int aid) async {
    if (await getConnectivityResult() < 0) return;
    try {
      await audioPlayer.play(UrlSource(_audioUrl(aid)));
    } catch (e) {
      debugPrint('Failed to play ${_audioUrl(aid)}: $e');
    }
  }

  /// Plays the pronunciation and waits until it finishes, fails or is
  /// interrupted by another call.
  static Future<void> tryToPlayAudioReturnOnCompletion(int aid) async {
    if (await getConnectivityResult() < 0) return;
    try {
      await audioPlayer.play(UrlSource(_audioUrl(aid)));
    } catch (e) {
      debugPrint('Failed to play ${_audioUrl(aid)}: $e');
      return;
    }
    // Starting a new source may emit `stopped` for the previous one, so only
    // start listening once this clip is playing.
    if (audioPlayer.state != PlayerState.playing) return;
    await audioPlayer.onPlayerStateChanged
        .firstWhere((state) => state != PlayerState.playing,
            orElse: () => PlayerState.disposed)
        .timeout(const Duration(seconds: 15),
            onTimeout: () => PlayerState.stopped);
  }
}
