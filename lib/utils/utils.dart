import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;

const platform = MethodChannel('app.ohtaigi.channel');

/// Assumes the given path is a text-file asset.
Future<String> getFileData(String path) => rootBundle.loadString(path);

/// Network type: 1 = Wi-Fi (or other unmetered), 0 = mobile, -1 = offline.
///
/// Compared against [OTGConfig.keyAutoPlayAudio] (0: always, 1: Wi-Fi only,
/// 2: never) to decide whether audio is played automatically.
Future<int> getConnectivityResult() async {
  final List<ConnectivityResult> results;
  try {
    results = await Connectivity().checkConnectivity();
  } catch (_) {
    return -1;
  }
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return 1;
  }
  if (results.contains(ConnectivityResult.mobile) ||
      results.contains(ConnectivityResult.vpn) ||
      results.contains(ConnectivityResult.other)) {
    return 0;
  }
  return -1;
}

/// Returns (and clears) the text the app was opened with through Android's
/// "揣臺語" text selection action.
Future<String> getSearchKeyword() async {
  try {
    return await platform.invokeMethod<String>('getSearchKeyword') ?? '';
  } catch (_) {
    // Not implemented on this platform (e.g. iOS).
    return '';
  }
}

Future<bool> isSearchKeywordEmpty() async {
  try {
    return await platform.invokeMethod<bool>('isSearchKeywordEmpty') ?? true;
  } catch (_) {
    return true;
  }
}

/// Called when text is selected with "揣臺語" while the app is already running.
void listenSearchKeyword(void Function(String keyword) onKeyword) {
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onSearchKeyword' && call.arguments is String) {
      onKeyword(call.arguments as String);
    }
  });
}
