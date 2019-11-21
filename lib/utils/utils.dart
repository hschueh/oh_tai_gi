import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart' show rootBundle;

// Assumes the given path is a text-file-asset.
Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

Future<int> getConnectivityResult() async{
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return 0;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return 1;
  }
  return 2;
}