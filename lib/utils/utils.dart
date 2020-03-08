import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;

import 'secret.dart';

const platform = const MethodChannel('app.ohtaigi.channel');

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
  return -1;
}

String getAdAppId() {
  if (Platform.isIOS) {
    return AdAppId["iOS"];
  } else if (Platform.isAndroid) {
    return AdAppId["Android"];
  }
  return null;
}
String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return BannerAdUnitId['iOS'];
  } else if (Platform.isAndroid) {
    return BannerAdUnitId['Android'];
  }
  return null;
}
Future<double> getBannerHeight() async{
  if (Platform.isIOS) {
  // On IPhone 8 emulator, the banner exceed strangely.
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //   String name = iosInfo.name;
  //   if(name.contains("X") || name.contains("11"))
  //     return 44;
  //   else
  //     return 20;
    return 48;
  } else if (Platform.isAndroid) {
    return 24;
  }
  return 24;
}

Future<String> getSearchKeyword() async {
  String searchKeyword = await platform.invokeMethod("getSearchKeyword");
  if (searchKeyword != null && searchKeyword.isNotEmpty) {
    return searchKeyword;
  } else {
    return "";
  }
}

Future<bool> isSearchKeywordEmpty() async {
  return await platform.invokeMethod("isSearchKeywordEmpty");
}