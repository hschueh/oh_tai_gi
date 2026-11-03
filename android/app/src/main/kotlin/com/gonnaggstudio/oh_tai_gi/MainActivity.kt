package com.gonnaggstudio.oh_tai_gi

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and handles the "揣臺語" (PROCESS_TEXT) action, which
 * lets users select text in any app and look it up in O̍h Tâi Gí.
 */
class MainActivity : FlutterActivity() {
    private var searchKeyword = ""
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        handleIntent(intent)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSearchKeyword" -> {
                        result.success(searchKeyword)
                        searchKeyword = ""
                    }
                    "isSearchKeywordEmpty" -> result.success(searchKeyword.isEmpty())
                    else -> result.notImplemented()
                }
            }
        }
    }

    // With launchMode="singleTop", selecting text a second time while the app
    // is running delivers the intent here instead of recreating the activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (handleIntent(intent)) {
            channel?.invokeMethod("onSearchKeyword", searchKeyword)
            searchKeyword = ""
        }
    }

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_PROCESS_TEXT || intent.type != "text/plain") {
            return false
        }
        val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        if (text.isNullOrBlank()) return false
        searchKeyword = text
        return true
    }

    companion object {
        private const val CHANNEL = "app.ohtaigi.channel"
    }
}
