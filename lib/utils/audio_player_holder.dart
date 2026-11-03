import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class AudioPlayerHolder {
  static final AudioPlayer audioPlayer = AudioPlayer();
  static final AudioPlayer _effectPlayer = AudioPlayer();
  static String prefAudioFormat = Platform.isIOS ? 'mp3' : 'ogg';

  static Future<void>? _contextReady;

  /// Mixes with other apps' audio instead of taking audio focus, like the
  /// old audioplayers 0.13 did. With focus, a pronunciation would stop the
  /// user's music, and the sound effects would cut off pronunciations (which
  /// pauses the player natively without notifying Dart).
  static Future<void> _ensureAudioContext() {
    return _contextReady ??= AudioPlayer.global
        .setAudioContext(AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build())
        .catchError((Object e) {
      debugPrint('Failed to set the audio context: $e');
    });
  }

  static String _audioUrl(int aid) =>
      'http://t.moedict.tw/${aid.toString().padLeft(5, '0')}.$prefAudioFormat';

  /// Plays a sound effect from `assets/audio/`.
  static Future<void> playLocal(String file) async {
    await _ensureAudioContext();
    try {
      await _effectPlayer.play(AssetSource('audio/$file'));
    } catch (e) {
      debugPrint('Failed to play $file: $e');
    }
  }

  static Future<void> tryToPlayAudio(int aid) async {
    if (await getConnectivityResult() < 0) return;
    await _ensureAudioContext();
    try {
      await audioPlayer.play(UrlSource(_audioUrl(aid)));
    } catch (e) {
      debugPrint('Failed to play ${_audioUrl(aid)}: $e');
    }
  }

  /// Plays the pronunciation and waits until it finishes or fails (at most
  /// 15 seconds). If another call starts a new clip meanwhile, this keeps
  /// waiting until that clip ends, like the old shared `finished` flag did.
  static Future<void> tryToPlayAudioReturnOnCompletion(int aid) async {
    if (await getConnectivityResult() < 0) return;
    await _ensureAudioContext();
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
