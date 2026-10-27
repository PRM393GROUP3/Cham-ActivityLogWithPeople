package com.cham.cham

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.cham.cham/widgets"
        private var methodChannel: MethodChannel? = null

        fun notifyWidgetLogged() {
            Handler(Looper.getMainLooper()).post {
                methodChannel?.invokeMethod("onWidgetLogged", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgets" -> {
                    ChamWidgetUpdater.updateAllWidgets(applicationContext)
                    result.success(true)
                }
                "pinWidget" -> {
                    val size = call.argument<String>("size") ?: "small"
                    val pinned = requestPinHomeWidget(size)
                    ChamWidgetUpdater.updateAllWidgets(applicationContext)
                    result.success(pinned)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        notifyWidgetLogged()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (methodChannel != null) {
            methodChannel?.setMethodCallHandler(null)
            methodChannel = null
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun requestPinHomeWidget(size: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return false
        }
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
        if (!appWidgetManager.isRequestPinAppWidgetSupported) {
            return false
        }
        val provider = if (size == "medium") {
            ComponentName(applicationContext, ChamMediumWidgetProvider::class.java)
        } else {
            ComponentName(applicationContext, ChamSmallWidgetProvider::class.java)
        }
        return appWidgetManager.requestPinAppWidget(provider, null, null)
    }
}
