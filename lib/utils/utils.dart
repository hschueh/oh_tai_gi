import 'package:flutter/services.dart' show rootBundle;

// Assumes the given path is a text-file-asset.
Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}