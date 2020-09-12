package com.gonnaggstudio.tshue_tai_gi

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  private var searchKeyword = ""

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)

    val action = intent.action
    val type = intent.type

    if (Intent.ACTION_PROCESS_TEXT == action && type != null) {
      if ("text/plain" == type) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          searchKeyword = intent.getStringExtra(Intent.EXTRA_PROCESS_TEXT)
        }
        println("searchKeyword is $searchKeyword")
      }
    }

    MethodChannel(getFlutterView(), "app.ohtaigi.channel").setMethodCallHandler { methodCall: MethodCall, result: MethodChannel.Result ->
      try {
        if (methodCall.method!!.contentEquals(charSequence = "getSearchKeyword")) {
          println("searchKeyword is ${searchKeyword}")
          result.success(searchKeyword)
          searchKeyword = ""
        } else if (methodCall.method!!.contentEquals("isSearchKeywordEmpty")) {
          println("searchKeyword is empty: ${if (searchKeyword.isEmpty()) "Yes" else "No"}")
          result.success(searchKeyword.isEmpty())
        }
      } catch (e: Exception) {
        result.notImplemented()
      }
    }
  }
}
